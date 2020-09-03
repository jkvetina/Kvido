CREATE OR REPLACE PACKAGE BODY wiki AS

    PROCEDURE desc_table (
        in_name VARCHAR2
    ) AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('| ID | Column name                    | Data type        | NN  | PK  | Comment |');
        DBMS_OUTPUT.PUT_LINE('| -: | :----------------------------- | :--------------- | :-: | :-: | :------ |');
        --
        FOR c IN (
            SELECT
                '| ' || LPAD(c.column_id, 2) || ' | ' || RPAD(c.column_name, 30) || ' | ' ||
                RPAD(DECODE(c.data_type,
                    'NUMBER(38)',   'INTEGER',
                    'TIMESTAMP(6)', 'TIMESTAMP',
                    'BFILE',        'BINARY FILE LOB',
                    data_type
                ), 16) || ' | ' || DECODE(c.nullable, 'N', 'Y', 'N') || ' | ' ||
                --CASE WHEN c.data_default IS NULL THEN 'N' ELSE 'Y' END  AS dv,
                NVL(k.pk, 'N') || ' | ' ||
                --NVL(k.uq, 'N')                                          AS uq,
                --NVL(k.fk, 'N')                                          AS fk,
                --CASE WHEN h.checks > 0 THEN 'Y' ELSE 'N' END            AS ch,
                m.comments || ' |' AS text
            FROM (
                SELECT c.table_name, c.column_name, c.column_id, c.nullable, c.data_default,
                    c.data_type ||
                    CASE
                        WHEN c.data_type LIKE '%CHAR%' OR c.data_type = 'RAW' THEN
                            DECODE(NVL(c.char_length, 0), 0, '',
                                '(' || c.char_length || DECODE(c.char_used, 'C', ' CHAR', '') || ')'
                            )
                        WHEN c.data_type = 'NUMBER' THEN
                            DECODE(NVL(c.data_precision || c.data_scale, 0), 0, '',
                                DECODE(NVL(c.data_scale, 0), 0, '(' || c.data_precision || ')',
                                    '(' || c.data_precision || ',' || c.data_scale || ')'
                                )
                            )
                    END AS data_type
                FROM user_tab_columns c
            ) c
            LEFT JOIN (
                SELECT table_name, column_name,
                    DECODE(MIN(constraint_type), 'P', 'Y', 'N') AS pk,
                    DECODE(MAX(constraint_type), 'U', 'Y', 'N') AS uq,
                    DECODE(INSTR(MIN(constraint_type) || MAX(constraint_type), 'R'), 0, 'N', 'Y') AS fk
                FROM (
                    SELECT c.table_name, c.column_name, c.column_id, n.constraint_type
                    FROM user_tab_columns c
                    JOIN user_tables t
                        ON t.table_name         = c.table_name
                    JOIN user_cons_columns m
                        ON m.table_name         = c.table_name
                        AND m.column_name       = c.column_name
                    JOIN user_constraints n
                        ON n.constraint_name    = m.constraint_name
                        AND n.constraint_type   IN ('P', 'R', 'U')
                )
                GROUP BY table_name, column_name
            ) k
                ON k.table_name     = c.table_name
                AND k.column_name   = c.column_name
            LEFT JOIN (
                SELECT c.table_name, c.column_name, COUNT(c.column_name) - 1 AS checks
                FROM user_tab_columns c
                JOIN user_tables t
                    ON t.table_name         = c.table_name
                JOIN user_cons_columns m
                    ON m.table_name         = c.table_name
                    AND m.column_name       = c.column_name
                JOIN user_constraints n
                    ON n.constraint_name    = m.constraint_name
                    AND n.constraint_type   = 'C'
                GROUP BY c.table_name, c.column_name
                HAVING COUNT(c.column_name) - 1 > 0
            ) h
                ON h.table_name     = c.table_name
                AND h.column_name   = c.column_name
            LEFT JOIN user_col_comments m
                ON m.table_name     = c.table_name
                AND m.column_name   = c.column_name
            WHERE c.table_name      = UPPER(in_name)
            ORDER BY c.table_name, c.column_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(c.text);
        END LOOP;
    END;



    PROCEDURE desc_view (
        in_name     VARCHAR2
    ) AS
        content     CLOB;
        offset      PLS_INTEGER         := 2;  -- skip first empty line
        amount      PLS_INTEGER         := 32767;
        buffer      VARCHAR2(32767);
        len         PLS_INTEGER;
        line        PLS_INTEGER         := 0;
    BEGIN
        FOR c IN (
            SELECT v.view_name, DBMS_METADATA.GET_DDL('VIEW', v.view_name) AS content
            FROM user_views v
            WHERE v.view_name = UPPER(in_name)
        ) LOOP
            len := DBMS_LOB.GETLENGTH(c.content);
            --
            WHILE offset < len LOOP
                amount := CASE WHEN INSTR(c.content, CHR(10), offset) = 0
                    THEN len - offset + 1
                    ELSE INSTR(c.content, CHR(10), offset) - offset
                    END;
                IF amount = 0 THEN
                    buffer := '';
                ELSE
                    DBMS_LOB.READ(c.content, amount, offset, buffer);
                END IF;
                --
                buffer  := REPLACE(REPLACE(buffer, CHR(13), ''), CHR(10), '');
                line    := line + 1;
                --
                IF line = 1 THEN
                    DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE VIEW ' || LOWER(in_name) || ' AS');
                ELSIF line = 2 THEN
                    DBMS_OUTPUT.PUT_LINE(LTRIM(buffer));
                ELSE
                    DBMS_OUTPUT.PUT_LINE(buffer);
                END IF;
                --
                IF INSTR(c.content, CHR(10), offset) = len THEN
                    buffer := '';
                END IF;
                offset := offset + amount + 1;
            END LOOP;
        END LOOP;
    END;



    PROCEDURE desc_spec (
        in_name         VARCHAR2,
        in_type         VARCHAR2    := NULL,
        in_overload     NUMBER      := 1
    ) AS
        in_package      CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_name, 1, INSTR(in_name, '.') - 1));
        in_module       CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_name, INSTR(in_name, '.') + 1));
        in_type__       CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_type, 1, 1));
    BEGIN
        DBMS_OUTPUT.PUT_LINE('');
        FOR c IN (
            SELECT s.text
            FROM logs_modules m
            JOIN user_source s
                ON s.name               = m.package_name
                AND s.type              = 'PACKAGE'
                AND s.line              BETWEEN m.spec_start AND m.spec_end
            WHERE m.package_name        = in_package
                AND m.module_name       = in_module
                AND m.module_type       LIKE in_type__ || '%'
                AND NVL(m.overload, 1)  = in_overload
        ) LOOP
            DBMS_OUTPUT.PUT(c.text);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END;



    PROCEDURE desc_body (
        in_name         VARCHAR2,
        in_type         VARCHAR2    := NULL,
        in_overload     NUMBER      := 1
    ) AS
        in_package      CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_name, 1, INSTR(in_name, '.') - 1));
        in_module       CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_name, INSTR(in_name, '.') + 1));
        in_type__       CONSTANT VARCHAR2(30) := UPPER(SUBSTR(in_type, 1, 1));
    BEGIN
        DBMS_OUTPUT.PUT_LINE('');
        FOR c IN (
            SELECT s.text
            FROM logs_modules m
            JOIN user_source s
                ON s.name               = m.package_name
                AND s.type              = 'PACKAGE BODY'
                AND s.line              BETWEEN m.body_start AND m.body_end
            WHERE m.package_name        = in_package
                AND m.module_name       = in_module
                AND m.module_type       LIKE in_type__ || '%'
                AND NVL(m.overload, 1)  = in_overload
        ) LOOP
            DBMS_OUTPUT.PUT(c.text);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END;



    PROCEDURE desc_package (
        in_package      VARCHAR2
    ) AS
        sum_public      PLS_INTEGER;
        sum_private     PLS_INTEGER;
        count_out       PLS_INTEGER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('# `' || LOWER(in_package) || '` package');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(
            'Source code: ' ||
            '[`packages/' || LOWER(in_package) || '.spec.sql`](../blob/master/packages/' || LOWER(in_package) || '.spec.sql), ' ||
            '[`packages/' || LOWER(in_package) || '.sql`](../blob/master/packages/' || LOWER(in_package) || '.sql)'
        );
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('<br />');
        --
        FOR c IN (
            SELECT
                m.package_name,
                m.group_line,
                m.group_end,
                x.line,
                REGEXP_SUBSTR(x.text, '^\s*--\s*(.*)\s*$', 1, 1, NULL, 1) AS text
            FROM (
                SELECT
                    m.name          AS package_name,
                    m.line          AS group_line,
                    MIN(x.line) - 1 AS group_end
                FROM (
                    SELECT x.*
                    FROM user_source x
                    WHERE x.name        = UPPER(in_package)
                        AND x.type      = 'PACKAGE'
                        AND REGEXP_LIKE(x.text, '^\s*--\s*###')
                ) m
                JOIN user_source x
                    ON x.name       = m.name
                    AND x.type      = 'PACKAGE'
                    AND x.line      > m.line
                    AND REGEXP_LIKE(x.text, '^\s*$')
                GROUP BY m.name, m.line
            ) m
            JOIN user_source x
                ON x.name       = m.package_name
                AND x.type      = 'PACKAGE'
                AND x.line      BETWEEN m.group_line AND m.group_end
            ORDER BY m.group_line, m.group_end, x.line
        ) LOOP
            IF c.line = c.group_line THEN  -- first group line
                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('');
            END IF;
            --
            DBMS_OUTPUT.PUT_LINE(c.text);
            --
            IF c.line = c.group_end THEN  -- last group line
                SELECT
                    SUM(CASE private WHEN 'Y' THEN 0 ELSE 1 END),
                    SUM(CASE private WHEN 'Y' THEN 1 ELSE 0 END),
                    COUNT(args_out)
                INTO sum_public, sum_private, count_out
                FROM logs_modules
                WHERE package_name  = UPPER(in_package)
                    AND group_line  = c.group_line;
                --
                IF sum_public > 0 OR sum_private > 0 THEN
                    DBMS_OUTPUT.PUT_LINE('| Module name | Type | ' || CASE WHEN sum_private > 0 THEN 'Private | ' END || 'IN | ' || CASE WHEN count_out > 0 THEN 'OUT | ' END || 'Lines | Description |');
                    DBMS_OUTPUT.PUT_LINE('| :---------- | :--: | ' || CASE WHEN sum_private > 0 THEN ':-----: | ' END || '-: | ' || CASE WHEN count_out > 0 THEN '--: | ' END || '----: | :---------- |');
                END IF;
                --
                FOR d IN (
                    SELECT
                        LOWER(package_name)         AS package_name,
                        LOWER(module_name)          AS module_name,
                        SUBSTR(module_type, 1, 1)   AS module_type,
                        overload,
                        private,
                        args_in,
                        args_out,
                        body_lines,
                        comment_,
                        f_id
                    FROM logs_modules
                    WHERE package_name  = UPPER(in_package)
                        AND group_line  = c.group_line
                    ORDER BY spec_start
                ) LOOP
                    IF d.f_id IS NOT NULL THEN
                        IF d.comment_ = '^' THEN
                            CONTINUE;       --ignore line
                        ELSE
                            d.module_type   := 'F + P';
                            d.overload      := '';
                        END IF;
                    END IF;
                    --
                    DBMS_OUTPUT.PUT_LINE (
                        '| [`' || d.module_name || '`](./packages-' || d.package_name || '.' || d.module_name || ')&' ||
                        'nbsp;<sup title="Overload">' || d.overload || '</sup> | ' ||
                        d.module_type   || ' | ' || CASE WHEN sum_private > 0 THEN d.private || ' | ' END ||
                        d.args_in       || ' | ' ||
                        CASE WHEN count_out > 0 THEN d.args_out || ' | ' END ||
                        d.body_lines    || ' | ' || d.comment_  || ' |'
                    );
                END LOOP;
                --
                DBMS_OUTPUT.PUT_LINE('');
                DBMS_OUTPUT.PUT_LINE('<br />');
            END IF;
        END LOOP;
    END;

BEGIN
    DBMS_SNAPSHOT.REFRESH(bug.view_logs_modules);
END;
/

