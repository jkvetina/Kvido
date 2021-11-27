CREATE OR REPLACE PACKAGE BODY gen AS

    in_in_prefix            VARCHAR2(4)     := 'in_';
    in_rec_prefix           VARCHAR2(4)     := 'rec.';
    in_minimal_space        PLS_INTEGER     := 5;
    in_tab_width            PLS_INTEGER     := 4;



    FUNCTION get_width (
        in_table_name           user_tables.table_name%TYPE,
        in_prefix               VARCHAR2
    )
    RETURN PLS_INTEGER AS
        out_size                PLS_INTEGER;
    BEGIN
        -- check tables/views
        SELECT MAX(LENGTH(c.column_name)) INTO out_size
        FROM user_tab_columns c
        WHERE c.table_name          = UPPER(in_table_name);
        --
        IF out_size IS NULL THEN
            -- check procedures and procedures in packages
            SELECT MAX(LENGTH(a.argument_name)) INTO out_size
            FROM user_arguments a
            WHERE a.package_name || '.' || a.object_name IN (UPPER(in_table_name), '.' || UPPER(in_table_name));
        END IF;
        --
        RETURN CEIL((NVL(LENGTH(in_prefix), 0) + in_minimal_space + out_size) / in_tab_width) * in_tab_width;
    END;



    PROCEDURE table_args (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    )
    AS
        width                   PLS_INTEGER;
    BEGIN
        width := gen.get_width (
            in_table_name           => in_table_name,
            in_prefix               => in_in_prefix
        );
        --
        FOR c IN (
            SELECT
                RPAD(in_in_prefix || LOWER(c.column_name), width)
                    || LOWER(c.table_name) || '.' ||
                    CASE WHEN c.nullable = 'N'
                        THEN LOWER(c.column_name) || '%TYPE'
                        ELSE RPAD(LOWER(c.column_name) || '%TYPE', width, ' ') || ' := NULL'
                        END
                    || CASE WHEN c.column_id < COUNT(*) OVER() THEN ',' END AS text
            FROM user_tab_columns c
            WHERE c.table_name          = in_table_name
            ORDER BY c.column_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(in_prepend || c.text);
        END LOOP;
    END;



    PROCEDURE table_rec (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    )
    AS
        width                   PLS_INTEGER;
    BEGIN
        width := gen.get_width (
            in_table_name           => in_table_name,
            in_prefix               => in_rec_prefix
        );
        --
        FOR c IN (
            SELECT
                RPAD(in_rec_prefix || LOWER(c.column_name), width)
                    || ':= ' || in_in_prefix || LOWER(c.column_name) || ';' AS text
            FROM user_tab_columns c
            WHERE c.table_name          = in_table_name
            ORDER BY c.column_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(in_prepend || c.text);
        END LOOP;
    END;



    PROCEDURE table_where (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    ) AS
    BEGIN
        FOR c IN (
            SELECT
                LOWER(c.column_name)    AS column_name,
                c.position              AS column_id,
                COUNT(*) OVER()         AS columns_,
                --
                CEIL((MAX(LENGTH(c.column_name)) OVER() + in_minimal_space) / in_tab_width) * in_tab_width AS len
            FROM user_cons_columns c
            JOIN user_constraints n
                ON n.constraint_name    = c.constraint_name
            WHERE n.table_name          = UPPER(in_table_name)
                AND n.constraint_type   = 'P'
            ORDER BY c.position
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                in_prepend || CASE WHEN c.column_id = 1 THEN 'WHERE ' ELSE '    AND ' END ||
                't.' || RPAD(c.column_name, c.len) || CASE WHEN c.column_id = 1 THEN '  ' END || '  = rec.' || c.column_name ||
                CASE WHEN c.column_id = c.columns_ THEN ';' END
            );
        END LOOP;
    END;



    PROCEDURE handler_call (
        in_procedure_name       user_procedures.procedure_name%TYPE,
        in_prepend              VARCHAR2                                        := '',
        in_app_id               apex_application_pages.application_id%TYPE      := NULL,
        in_page_id              apex_application_pages.page_id%TYPE             := NULL
    )
    AS
        width                   PLS_INTEGER;
    BEGIN
        width := gen.get_width (
            in_table_name           => in_procedure_name,
            in_prefix               => ''
        );
        --
        DBMS_OUTPUT.PUT(in_prepend);
        --
        FOR c IN (
            SELECT a.data_type
            FROM user_arguments a
            WHERE a.package_name || '.' || a.object_name IN (UPPER(in_procedure_name), '.' || UPPER(in_procedure_name))
                AND a.argument_name IS NULL
        ) LOOP
            DBMS_OUTPUT.PUT(c.data_type || ' := ');
        END LOOP;
        --
        DBMS_OUTPUT.PUT_LINE(LOWER(in_procedure_name) || ' (');
        --
        FOR c IN (
            SELECT
                '    ' || RPAD(LOWER(c.column_name), width, ' ')
                    || '=> :' ||
                    CASE WHEN c.column_name = 'IN_ACTION' THEN 'APEX$ROW_STATUS'
                        ELSE
                            CASE
                                WHEN NULLIF(in_page_id, 0) IS NOT NULL
                                    THEN 'P' || TO_CHAR(in_page_id) || '_' END
                            || REGEXP_REPLACE(c.column_name, '^(' || UPPER(in_in_prefix) || ')', '')
                            || CASE WHEN c.column_id < COUNT(*) OVER() THEN ',' END
                        END AS text
            FROM (
                SELECT c.column_name, c.column_id
                FROM user_tab_columns c
                WHERE c.table_name = UPPER(in_procedure_name)
                UNION ALL
                SELECT a.argument_name, a.position
                FROM user_arguments a
                WHERE a.package_name || '.' || a.object_name IN (UPPER(in_procedure_name), '.' || UPPER(in_procedure_name))
                    AND a.argument_name IS NOT NULL
            ) c
            LEFT JOIN apex_application_page_items i
                ON i.application_id     = in_app_id
                AND i.page_id           = in_page_id
                AND i.item_name         = 'P' || TO_CHAR(i.page_id) || '_' || REGEXP_REPLACE(c.column_name, '^(' || UPPER(in_in_prefix) || ')', '')
            ORDER BY c.column_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(in_prepend || c.text);
        END LOOP;
        --
        DBMS_OUTPUT.PUT_LINE(in_prepend || ');');
    END;



    PROCEDURE create_handler (
        in_table_name           user_tables.table_name%TYPE,
        in_target_table         user_tables.table_name%TYPE             := NULL,
        in_proc_prefix          user_procedures.procedure_name%TYPE     := 'save_'
    )
    AS
        width                   PLS_INTEGER;
    BEGIN
        width := gen.get_width (
            in_table_name           => in_table_name,
            in_prefix               => in_in_prefix
        );
        --
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('    PROCEDURE ' || LOWER(in_proc_prefix || in_table_name) || ' (');
        --
        DBMS_OUTPUT.PUT_LINE('        ' || RPAD('in_action', width) || 'CHAR,');  --:APEX$ROW_STATUS
        --
        gen.table_args (
            in_table_name           => in_table_name,
            in_prepend              => '        '
        );
        --
        DBMS_OUTPUT.PUT_LINE('    ) AS');
        DBMS_OUTPUT.PUT_LINE('        ' || RPAD('rec', width) || LOWER(NVL(in_target_table, in_table_name)) || '%ROWTYPE;');
        DBMS_OUTPUT.PUT_LINE('    BEGIN');
        DBMS_OUTPUT.PUT_LINE('        tree.log_module();');
        DBMS_OUTPUT.PUT_LINE('        --');
        --
        gen.table_rec (
            in_table_name           => NVL(in_target_table, in_table_name),
            in_prepend              => '        '
        );
        --
        DBMS_OUTPUT.PUT_LINE('        --');
        DBMS_OUTPUT.PUT_LINE('        DELETE FROM ' || LOWER(NVL(in_target_table, in_table_name)) || ' t');
        --
        gen.table_where (
            in_table_name           => in_table_name,
            in_prepend              => '        '
        );
        --
        DBMS_OUTPUT.PUT_LINE('        --');
        DBMS_OUTPUT.PUT_LINE('        BEGIN');
        DBMS_OUTPUT.PUT_LINE('            INSERT INTO ' || LOWER(NVL(in_target_table, in_table_name)));
        DBMS_OUTPUT.PUT_LINE('            VALUES rec;');
        DBMS_OUTPUT.PUT_LINE('        EXCEPTION');
        DBMS_OUTPUT.PUT_LINE('        WHEN DUP_VAL_ON_INDEX THEN');
        DBMS_OUTPUT.PUT_LINE('            UPDATE ' || LOWER(NVL(in_target_table, in_table_name)) || ' t');
        DBMS_OUTPUT.PUT_LINE('            SET ROW = rec');
        --
        gen.table_where (
            in_table_name           => in_table_name,
            in_prepend              => '            '
        );
        --
        DBMS_OUTPUT.PUT_LINE('        --');
        DBMS_OUTPUT.PUT_LINE('        tree.update_timer();');
        DBMS_OUTPUT.PUT_LINE('    EXCEPTION');
        DBMS_OUTPUT.PUT_LINE('    WHEN tree.app_exception THEN');
        DBMS_OUTPUT.PUT_LINE('        RAISE;');
        DBMS_OUTPUT.PUT_LINE('    WHEN OTHERS THEN');
        DBMS_OUTPUT.PUT_LINE('        tree.raise_error();');
        DBMS_OUTPUT.PUT_LINE('    END;');
    END;

END;
/
