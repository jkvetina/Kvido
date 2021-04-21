CREATE OR REPLACE PACKAGE BODY uploader AS

    PROCEDURE upload_file (
        in_session_id           sessions.session_id%TYPE,
        in_file_name            uploaded_files.file_name%TYPE,
        in_target               uploaded_files.uploader_id%TYPE     := NULL
    ) AS
        rec                     uploaded_files%ROWTYPE;
    BEGIN
        tree.log_module(in_session_id, in_file_name, in_target);
        --
        rec.app_id := sess.get_app_id();

        -- check uploader
        IF in_target IS NOT NULL THEN
            BEGIN
                SELECT u.uploader_id INTO rec.uploader_id
                FROM uploaders u
                WHERE u.app_id          = rec.app_id
                    AND u.uploader_id   = in_target;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                tree.raise_error('UPLOADER_MISSING');
            END;
        END IF;

        -- store files
        FOR c IN (
            SELECT
                f.name,
                f.blob_content,
                f.mime_type
            FROM apex_application_temp_files f
            WHERE f.name = in_file_name
        ) LOOP
            rec.file_name       := c.name;
            rec.file_size       := DBMS_LOB.GETLENGTH(c.blob_content);
            rec.mime_type       := c.mime_type;
            rec.blob_content    := c.blob_content;
            --
            INSERT INTO uploaded_files VALUES rec;
        END LOOP;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE upload_files (
        in_session_id           sessions.session_id%TYPE
    ) AS
        in_uploader_id          CONSTANT uploaders.uploader_id%TYPE := apex.get_item('$TARGET');
        --
        multiple_files          APEX_T_VARCHAR2;
    BEGIN
        /*
        -- uploader is posted in different session
        APEX_SESSION.ATTACH (
            p_app_id        => sess.get_app_id(),
            p_page_id       => sess.get_page_id(),
            p_session_id    => in_session_id
        );
        */
        --
        tree.log_module(in_session_id, in_uploader_id);
        --
        multiple_files := APEX_STRING.SPLIT(apex.get_item('$UPLOAD'), ':');
        FOR i IN 1 .. multiple_files.COUNT LOOP
            tree.log_debug(multiple_files(i));
        END LOOP;
        --
        FOR i IN 1 .. multiple_files.COUNT LOOP
            uploader.upload_file (
                in_session_id   => in_session_id,
                in_file_name    => multiple_files(i),
                in_target       => in_uploader_id
            );
            --
            uploader.parse_file (
                in_file_name    => multiple_files(i),
                in_uploader_id  => in_uploader_id
            );
            --
            COMMIT;             -- important, otherwise dynamic SQL may not see imported data
        END LOOP;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    FUNCTION get_basename (
        in_file_name            uploaded_files.file_name%TYPE
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN REGEXP_SUBSTR(in_file_name, '([^/]*)$');
    END;



    PROCEDURE parse_file (
        in_file_name            uploaded_file_sheets.file_name%TYPE,
        in_uploader_id          uploaded_file_sheets.uploader_id%TYPE       := NULL
    ) AS
    BEGIN
        tree.log_module(in_file_name, in_uploader_id);

        -- cleanup existing rows
        DELETE FROM uploaded_file_cols      WHERE file_name = in_file_name;
        DELETE FROM uploaded_file_sheets    WHERE file_name = in_file_name;

        -- analyze all sheets in file
        FOR c IN (
            SELECT
                f.file_name,
                f.blob_content,
                --
                p.sheet_sequence        AS sheet_id,
                p.sheet_file_name       AS sheet_xml_id,
                p.sheet_display_name    AS sheet_name,
                --
                APEX_DATA_PARSER.DISCOVER (
                    p_content           => f.blob_content,
                    p_file_name         => f.file_name,
                    p_xlsx_sheet_name   => p.sheet_file_name,
                    p_max_rows          => 100000
                )                       AS profile_json
            FROM uploaded_files f,
                TABLE(APEX_DATA_PARSER.GET_XLSX_WORKSHEETS(
                    p_content           => f.blob_content
                )) p
            WHERE f.file_name           = in_file_name
                AND in_file_name        LIKE '%.xlsx'
            UNION ALL
            SELECT
                f.file_name,
                f.blob_content,
                --
                1                       AS sheet_id,
                '-'                     AS sheet_xml_id,
                '-'                     AS sheet_name,
                --
                APEX_DATA_PARSER.DISCOVER (
                    p_content           => f.blob_content,
                    p_file_name         => f.file_name,
                    p_max_rows          => 100000
                )                       AS profile_json
            FROM uploaded_files f
            WHERE f.file_name           = in_file_name
                AND in_file_name        NOT LIKE '%.xls%'
        ) LOOP
            -- create sheet record
            INSERT INTO uploaded_file_sheets (
                file_name, sheet_id, sheet_xml_id, sheet_name,
                sheet_cols, sheet_rows, app_id, uploader_id, profile_json
            )
            VALUES (
                c.file_name,
                c.sheet_id,
                c.sheet_xml_id,
                c.sheet_name,
                JSON_VALUE(c.profile_json, '$."columns".size()' RETURNING NUMBER),      -- cols
                JSON_VALUE(c.profile_json, '$."parsed-rows"'    RETURNING NUMBER) - 1,  -- rows
                sess.get_app_id(),
                in_uploader_id,
                c.profile_json
            );

            -- create columns records
            INSERT INTO uploaded_file_cols (
                file_name, sheet_id, column_id, column_name, data_type, format_mask
            )
            SELECT
                c.file_name,
                c.sheet_id,
                column_position                 AS column_id,
                REPLACE(column_name, ']', '_')  AS column_name,
                data_type,
                REPLACE(format_mask, '"', '')   AS format_mask
            FROM TABLE(APEX_DATA_PARSER.GET_COLUMNS(c.profile_json));
        END LOOP;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE process_file_sheet (
        in_file_name            uploaded_file_sheets.file_name%TYPE,
        in_sheet_id             uploaded_file_sheets.sheet_id%TYPE,
        in_uploader_id          uploaded_file_sheets.uploader_id%TYPE,
        in_commit               VARCHAR2                                    := NULL
    ) AS
        uploader_procedure      user_procedures.object_name%TYPE;
        pre_procedure           uploaders.pre_procedure%TYPE;
        post_procedure          uploaders.pre_procedure%TYPE;
    BEGIN
        tree.log_module(in_file_name, in_sheet_id, in_uploader_id, in_commit);

        -- check for pre/post processing procedures
        SELECT u.pre_procedure, u.post_procedure
        INTO pre_procedure, post_procedure
        FROM uploaders u
        WHERE u.app_id          = sess.get_app_id()
            AND u.uploader_id   = in_uploader_id;
        --
        IF pre_procedure IS NOT NULL THEN
            BEGIN
                EXECUTE IMMEDIATE
                    'BEGIN ' || pre_procedure || '; END;';
            EXCEPTION
            WHEN tree.app_exception THEN
                RAISE;
            WHEN OTHERS THEN
                tree.raise_error('PRE_PROCEDURE_FAILED');
            END;
        END IF;

        -- check if customized upload procedure exists
        BEGIN
            SELECT p.object_name INTO uploader_procedure
            FROM user_procedures p
            WHERE p.object_name         = uploader.uploader_prefix || in_uploader_id
                AND p.procedure_name    IS NULL
                AND p.object_type       = 'PROCEDURE';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            tree.raise_error('UPLOADER_CODE_MISSING', uploader.uploader_prefix || in_uploader_id);
        END;

        -- execute procedure
        EXECUTE IMMEDIATE
            'BEGIN ' || uploader_procedure || '(' ||
            'in_file_name    => :1, ' ||
            'in_sheet_id     => :2, ' ||
            'in_uploader_id  => :3,'  ||
            'in_commit       => :4'   ||
            '); END;'
            USING in_file_name, in_sheet_id, in_uploader_id, in_commit;

        -- move data to collections so we can have dynamic report in APEX
        uploader.copy_uploaded_data_to_collection(in_uploader_id);

        -- check for post processing procedure
        IF post_procedure IS NOT NULL THEN
            BEGIN
                EXECUTE IMMEDIATE
                    'BEGIN ' || post_procedure || '; END;';
            EXCEPTION
            WHEN tree.app_exception THEN
                RAISE;
            WHEN OTHERS THEN
                tree.raise_error('POST_PROCEDURE_FAILED');
            END;
        END IF;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE copy_uploaded_data_to_collection (
        in_uploader_id          uploaders.uploader_id%TYPE,
        in_header_name          VARCHAR2                    := '$HEADER_'  -- to rename cols from apex_collections view
    ) AS
        in_collection           CONSTANT VARCHAR2(30)       := 'SQL_' || sess.get_session_id();  -- used in view p800_sheet_rows
        in_query                VARCHAR2(32767);
        --
        out_cols                PLS_INTEGER;
        out_cursor              PLS_INTEGER                 := DBMS_SQL.OPEN_CURSOR;
        out_desc                DBMS_SQL.DESC_TAB;
    BEGIN
        tree.log_module(in_uploader_id, in_header_name);

        -- get target table
        SELECT
            'SELECT t.' ||
            LISTAGG(CASE WHEN c.column_id > 5 THEN LOWER(c.column_name) ELSE c.column_name END, ', t.') WITHIN GROUP (ORDER BY c.column_id) ||
            ' FROM ' || uploader.get_u$_table_name(u.target_table) || ' t'
        INTO in_query
        FROM uploaders u
        JOIN user_tab_cols c
            ON c.table_name         = uploader.get_u$_table_name(u.target_table)
        WHERE u.app_id              = sess.get_app_id()
            AND u.uploader_id       = in_uploader_id
            AND c.column_name       NOT IN (
                'ORA_ERR_TAG$',
                'ORA_ERR_ROWID$',
                'UPDATED_BY',
                'UPDATED_AT'
            )
        GROUP BY u.target_table;
        --
        tree.log_debug(in_query);

        -- initialize and populate collection
        IF APEX_COLLECTION.COLLECTION_EXISTS(in_collection) THEN
            APEX_COLLECTION.DELETE_COLLECTION(in_collection);
        END IF;
        --
        APEX_COLLECTION.CREATE_COLLECTION_FROM_QUERY (
            p_collection_name   => in_collection,
            p_query             => in_query
        );
        --
        DBMS_SQL.PARSE(out_cursor, in_query, DBMS_SQL.NATIVE);
        DBMS_SQL.DESCRIBE_COLUMNS(out_cursor, out_cols, out_desc);
        DBMS_SQL.CLOSE_CURSOR(out_cursor);

        -- populate APEX items
        FOR i IN 4 .. out_desc.COUNT LOOP       -- skip first 3 (internal) rows
            apex.set_item (
                in_name      => in_header_name || LPAD(i, 3, 0),
                in_value     => out_desc(i).col_name
            );
        END LOOP;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE delete_file (
        in_file_name            uploaded_files.file_name%TYPE
    ) AS
        file_exists             CHAR(1) := 'N';
    BEGIN
        tree.log_module(in_file_name);

        -- check file ownership
        BEGIN
            SELECT 'Y' INTO file_exists
            FROM uploaded_files f
            WHERE f.file_name = in_file_name
                AND (
                    f.created_by = sess.get_user_id()
                    OR auth.is_developer = 'Y'
                );
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            tree.raise_error('FILE_ACCESS_DENIED');
        END;

        -- proceed
        DELETE FROM uploaded_file_cols u
        WHERE u.file_name = in_file_name;
        --
        DELETE FROM uploaded_file_sheets u
        WHERE u.file_name = in_file_name;
        --
        DELETE FROM uploaded_files u
        WHERE u.file_name = in_file_name;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE download_file (
        in_file_name            uploaded_files.file_name%TYPE
    ) AS
        out_blob_content        uploaded_files.blob_content%TYPE;
        out_mime_type           uploaded_files.mime_type%TYPE;
    BEGIN
        tree.log_module(in_file_name);
        --
        -- @TODO: AUTH
        --
        SELECT f.blob_content, f.mime_type
        INTO out_blob_content, out_mime_type
        FROM uploaded_files f
        WHERE f.file_name = in_file_name;
        --
        HTP.INIT;
        OWA_UTIL.MIME_HEADER(out_mime_type, FALSE);
        HTP.P('Content-Type: application/octet-stream');
        HTP.P('Content-Length: ' || DBMS_LOB.GETLENGTH(out_blob_content));
        HTP.P('Content-Disposition: attachment; filename="' || uploader.get_basename(in_file_name) || '"');
        HTP.P('Cache-Control: max-age=0');
        --
        OWA_UTIL.HTTP_HEADER_CLOSE;
        WPG_DOCLOAD.DOWNLOAD_FILE(out_blob_content);
        APEX_APPLICATION.STOP_APEX_ENGINE;              -- throws ORA-20876 Stop APEX Engine
    EXCEPTION
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        NULL;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE create_uploader (
        in_uploader_id          uploaders.uploader_id%TYPE,
        in_clear_current        BOOLEAN                                 := TRUE
    ) AS
        rec                     uploaders%ROWTYPE;
    BEGIN
        tree.log_module(in_uploader_id);
        --
        BEGIN
            SELECT p.table_name, p.page_id
            INTO rec.target_table, rec.target_page_id
            FROM p805_uploaders_possible p
            WHERE NVL(p.uploader_id, p.table_name) = in_uploader_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            tree.raise_error('UPLOADER_NOT_POSSIBLE');
        END;
        --
        rec.app_id              := sess.get_app_id();
        rec.uploader_id         := in_uploader_id;
        --
        BEGIN
            INSERT INTO uploaders VALUES rec;
        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE uploaders u
            SET u.target_table      = rec.target_table,
                u.target_page_id    = rec.target_page_id
            WHERE u.app_id          = rec.app_id
                AND u.uploader_id   = rec.uploader_id;
        END;

        -- rebuild DML Err table
        uploader.rebuild_dml_err_table (
            in_table_name       => rec.target_table
        );

        -- update mappings and procedure
        uploader.create_uploader_mappings (
            in_uploader_id      => in_uploader_id,
            in_clear_current    => in_clear_current
        );
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE create_uploader_mappings (
        in_uploader_id          uploaders_mapping.uploader_id%TYPE,
        in_clear_current        BOOLEAN                                 := FALSE
    ) AS
        TYPE list_mappings      IS TABLE OF uploaders_mapping%ROWTYPE INDEX BY PLS_INTEGER;
        curr_mappings           list_mappings;
    BEGIN
        tree.log_module(in_uploader_id, CASE WHEN in_clear_current THEN 'Y' END);

        -- store current mappings
        SELECT m.*
        BULK COLLECT INTO curr_mappings
        FROM uploaders_mapping m
        WHERE m.app_id          = sess.get_app_id()
            AND m.uploader_id   = in_uploader_id;

        -- delete not existing columns
        DELETE FROM uploaders_mapping m
        WHERE m.app_id          = sess.get_app_id()
            AND m.uploader_id   = in_uploader_id;

        -- merge existing columns
        FOR c IN (
            SELECT m.*
            FROM p805_uploaders_mapping m
            WHERE m.uploader_id = in_uploader_id
        ) LOOP
            INSERT INTO uploaders_mapping (
                app_id, uploader_id, target_column,
                is_key, is_nn, is_hidden, source_column, overwrite_value
            )
            VALUES (
                c.app_id,
                c.uploader_id,
                c.target_column,
                c.is_key_def,
                c.is_nn_def,
                c.is_hidden_def,
                NVL(c.source_column, c.target_column),
                c.overwrite_value
            );
        END LOOP;

        -- set previous values (for some columns)
        IF curr_mappings.FIRST IS NOT NULL THEN
            IF NOT in_clear_current THEN
                FOR i IN curr_mappings.FIRST .. curr_mappings.LAST LOOP
                    UPDATE uploaders_mapping m
                    SET m.is_key                = curr_mappings(i).is_key,
                        m.is_nn                 = curr_mappings(i).is_nn,
                        m.is_hidden             = curr_mappings(i).is_hidden,
                        m.source_column         = curr_mappings(i).source_column,
                        m.overwrite_value       = curr_mappings(i).overwrite_value
                    WHERE m.app_id              = curr_mappings(i).app_id
                        AND m.uploader_id       = curr_mappings(i).uploader_id
                        AND m.target_column     = curr_mappings(i).target_column;
                END LOOP;
            ELSE
                FOR i IN curr_mappings.FIRST .. curr_mappings.LAST LOOP
                    UPDATE uploaders_mapping m
                    SET m.overwrite_value       = curr_mappings(i).overwrite_value
                    WHERE m.app_id              = curr_mappings(i).app_id
                        AND m.uploader_id       = curr_mappings(i).uploader_id
                        AND m.target_column     = curr_mappings(i).target_column;
                END LOOP;
            END IF;
        END IF;

        -- rebuild uploader procedure
        uploader.generate_procedure (
            in_uploader_id      => in_uploader_id
        );
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    FUNCTION get_procedure_name (
        in_uploader_id          uploaders.uploader_id%TYPE
    )
    RETURN uploaders.target_table%TYPE AS
    BEGIN
        RETURN UPPER('UPLOADER_' || in_uploader_id);
    END;



    FUNCTION get_u$_table_name (
        in_table_name           uploaders.target_table%TYPE
    )
    RETURN uploaders.target_table%TYPE AS
    BEGIN
        RETURN in_table_name || uploader.dml_tables_postfix;
    END;



    PROCEDURE rebuild_dml_err_table (
        in_table_name           uploaders.target_table%TYPE
    ) AS
        err_table_name          uploaders.target_table%TYPE;
    BEGIN
        err_table_name          := uploader.get_u$_table_name(in_table_name);
        --
        tree.log_module(in_table_name, err_table_name, uploader.dml_tables_owner);

        -- drop table if exists
        BEGIN
            DBMS_UTILITY.EXEC_DDL_STATEMENT('DROP TABLE ' || err_table_name);
        EXCEPTION
        WHEN OTHERS THEN
            NULL;
        END;

        -- refresh ERR table
        DBMS_ERRLOG.CREATE_ERROR_LOG (
            dml_table_name          => in_table_name,
            err_log_table_name      => err_table_name,
            err_log_table_owner     => uploader.dml_tables_owner,
            err_log_table_space     => NULL,
            skip_unsupported        => TRUE
        );

        -- fix unsupported datatype
        DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE ' || err_table_name || ' MODIFY ORA_ERR_ROWID$ VARCHAR2(30)');

        -- fix too long columns
        FOR c IN (
            SELECT c.column_name
            FROM user_tab_cols c
            WHERE c.table_name      = err_table_name
                AND c.column_name   NOT LIKE 'ORA\_%\_%$' ESCAPE '\'
                AND c.data_length   > 4000
        ) LOOP
            DBMS_UTILITY.EXEC_DDL_STATEMENT('ALTER TABLE ' || err_table_name || ' MODIFY ' || c.column_name || ' VARCHAR2(4000)');
        END LOOP;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE uploader_template (
        in_file_name            uploaded_file_sheets.file_name%TYPE,
        in_sheet_id             uploaded_file_sheets.sheet_id%TYPE,
        in_uploader_id          uploaded_file_sheets.uploader_id%TYPE,
        in_commit               VARCHAR2                                    := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        in_target_table         uploaders.target_table%TYPE;
        in_sheet_name           uploaded_file_sheets.sheet_name%TYPE;
        in_user_id              CONSTANT uploaded_files.created_by%TYPE     := sess.get_user_id();
        in_app_id               CONSTANT uploaded_files.app_id%TYPE         := sess.get_app_id();
        in_sysdate              CONSTANT DATE                               := SYSDATE;
        --
        rows_to_insert          uploader.target_rows_t      := uploader.target_rows_t();
        rows_to_update          uploader.target_rows_t      := uploader.target_rows_t();
        rows_to_delete          uploader.target_rows_t      := uploader.target_rows_t();
        --
        indexes_insert          uploader.target_ids_t       := uploader.target_ids_t();
        indexes_update          uploader.target_ids_t       := uploader.target_ids_t();
        --
        rows_inserted#          SIMPLE_INTEGER := 0;
        rows_updated#           SIMPLE_INTEGER := 0;
        rows_deleted#           SIMPLE_INTEGER := 0;
        rows_errors#            SIMPLE_INTEGER := 0;
        --
        idx                     PLS_INTEGER;
        --
        TYPE target_table_t
            IS TABLE OF         uploaders_u$%ROWTYPE INDEX BY PLS_INTEGER;  /** STAGE_TABLE */
        --
        target_table            target_table_t;
        r                       SYS_REFCURSOR;
        --
        q_start                 VARCHAR2(4000);
        q_end                   VARCHAR2(4000);
        q_dynamic               VARCHAR2(32767);
        --
        module_id               logs.log_id%TYPE;
    BEGIN
        module_id := tree.log_module(in_file_name, in_sheet_id, in_uploader_id, in_commit);
        --
        SAVEPOINT before_merge;

        -- get sheet name for possible use in rows replacements
        BEGIN
            SELECT s.sheet_name, uploader.get_u$_table_name(u.target_table)
            INTO in_sheet_name, in_target_table
            FROM uploaded_file_sheets s
            JOIN uploaders u
                ON u.app_id         = s.app_id
                AND u.uploader_id   = in_uploader_id
            WHERE s.file_name       = in_file_name
                AND s.sheet_id      = in_sheet_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            tree.raise_error('SHEET_MISSING');
        END;

        -- get delete_flag column name
        /*
        BEGIN
            SELECT 'COL' || LPAD(c.column_id, 3, '0') INTO delete_flag_col
            FROM uploaded_file_cols c
            WHERE c.file_name       = in_file_name
                AND c.column_name   = uploader.delete_flag_name;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        END;
        */

        -- create query for bulk operation
        q_start :=  'SELECT'                                            || CHR(10) ||
                    '    p.line_number - 1       AS ORA_ERR_NUMBER$,'   || CHR(10) ||
                    '    NULL                    AS ORA_ERR_MESG$,'     || CHR(10) ||
                    '    NULL                    AS ORA_ERR_ROWID$,'    || CHR(10) ||
                    '    NULL                    AS ORA_ERR_OPTYP$,'    || CHR(10) ||
                    '    sess.get_session_id()   AS ORA_ERR_TAG$,'      || CHR(10);
        --
        q_end :=    'FROM uploaded_files f'                             || CHR(10) ||
                    'JOIN uploaded_file_sheets s'                       || CHR(10) ||
                    '    ON s.file_name          = f.file_name'         || CHR(10) ||
                    '    AND s.sheet_id          = ' || in_sheet_id     || CHR(10) ||
                    'CROSS JOIN TABLE(APEX_DATA_PARSER.PARSE('          || CHR(10) ||
                    '        p_content           => f.blob_content,'    || CHR(10) ||
                    '        p_file_name         => f.file_name,'       || CHR(10) ||
                    '        p_xlsx_sheet_name   => s.sheet_xml_id,'    || CHR(10) ||
                    '        p_skip_rows         => 1'                  || CHR(10) ||
                    '    )) p'                                          || CHR(10) ||
                    'WHERE f.file_name = ''' || in_file_name || '''';

        -- bulk collect rows from uploaded file into memory
        FOR c IN (
            SELECT
                CASE
                    WHEN m.overwrite_value IS NOT NULL
                        THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                            m.overwrite_value,
                            '${LINE_NUMBER}',   'p.line_number - 1'),
                            '${FILE_NAME}',     '''' || in_file_name  || ''''),
                            '${SHEET_NAME}',    '''' || in_sheet_name || ''''),
                            '${USER_ID}',       'sess.get_user_id()'),
                            '${APP_ID}',        'sess.get_app_id()'),
                            '${SYSDATE}',       'SYSDATE'),
                            '${THIS}',          CASE WHEN f.column_id > 0 THEN 'p.COL' || LPAD(f.column_id, 3, '0') ELSE 'NULL' END
                        )
                    WHEN f.column_id > 0
                        THEN 'p.COL' || LPAD(f.column_id, 3, '0')
                    ELSE 'NULL'
                    END || ' AS ' || LOWER(c.column_name) || ',' AS line_
            FROM user_tab_cols c
            LEFT JOIN uploaders_mapping m
                ON m.app_id             = sess.get_app_id()
                AND m.uploader_id       = in_uploader_id
                AND m.target_column     = c.column_name
            LEFT JOIN uploaded_file_cols f
                ON f.column_name        = m.source_column
                AND f.file_name         = in_file_name
                AND f.sheet_id          = in_sheet_id
            WHERE c.table_name          = in_target_table
                AND c.column_name       NOT LIKE 'ORA\_%\_%$' ESCAPE '\'
            ORDER BY c.column_id
        ) LOOP
            q_dynamic := q_dynamic || c.line_ || CHR(10);
        END LOOP;
        --
        q_dynamic := q_start || RTRIM(RTRIM(q_dynamic, CHR(10)), ',') || CHR(10) || q_end;
        --
        --tree.attach_clob(q_dynamic, 'DYNAMIC');
        --
        r := uploader.get_cursor_from_query(q_dynamic);
        --
        FETCH r BULK COLLECT INTO target_table LIMIT 100000;
        CLOSE r;
        --
        tree.log_debug('COLLECTION READY', target_table.COUNT);

        -- split rows into rows for delete or insert
        FOR i IN 1 .. target_table.COUNT LOOP
            IF target_table(i).ORA_ERR_OPTYP$ = uploader.delete_flag_value THEN
                rows_to_delete(i) := i;
            ELSE
                rows_to_insert(i) := i;
            END IF;
        END LOOP;

        -- delete flagged rows
        BEGIN
            FORALL i IN INDICES OF rows_to_delete
            DELETE FROM uploaders t  /** TARGET_TABLE */
            WHERE /** GENERATE_WHERE:START(3) */
                    t.app_id        = target_table(i).app_id
                AND t.uploader_id   = target_table(i).uploader_id
                ;/** GENERATE_WHERE:END */
        END;

        -- calculate deleted rows
        idx := rows_to_delete.FIRST;
        WHILE (idx IS NOT NULL) LOOP
            IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
                rows_deleted# := rows_deleted# + 1;
                target_table(idx).ORA_ERR_OPTYP$ := 'D';
            END IF;
            --
            idx := rows_to_delete.NEXT(idx);
        END LOOP;
        --
        tree.log_debug('DELETE DONE', rows_deleted#);

        -- prepare index maps for exceptions
        idx := rows_to_insert.FIRST;
        WHILE (idx IS NOT NULL) LOOP
            indexes_insert.EXTEND;
            indexes_insert(indexes_insert.LAST) := idx;
            idx := rows_to_insert.NEXT(idx);
        END LOOP;

        -- insert rows first, then try to update failed rows
        BEGIN
            FORALL i IN INDICES OF rows_to_insert
            SAVE EXCEPTIONS
            INSERT INTO uploaders (  /** TARGET_TABLE */
                /** GENERATE_INSERT:START(3) */
                app_id,
                uploader_id,
                target_table,
                target_page_id,
                pre_procedure,
                post_procedure,
                is_active,
                updated_by,
                updated_at
                /** GENERATE_INSERT:END */
            )
            VALUES (
                /** GENERATE_VALUES:START(3) */
                target_table(i).app_id,
                target_table(i).uploader_id,
                target_table(i).target_table,
                target_table(i).target_page_id,
                target_table(i).pre_procedure,
                target_table(i).post_procedure,
                target_table(i).is_active,
                target_table(i).updated_by,
                target_table(i).updated_at
                /** GENERATE_VALUES:END */
            );
        EXCEPTION
        WHEN uploader.forall_failed THEN
            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                idx := indexes_insert(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);

                -- on dup_val_on_index mark row for update
                IF SQL%BULK_EXCEPTIONS(i).ERROR_CODE = 1 THEN
                    rows_to_update(idx) := idx;
                    CONTINUE;
                END IF;

                -- otherwise mark as error
                rows_errors#                        := rows_errors# + 1;
                target_table(idx).ORA_ERR_MESG$     := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
                target_table(idx).ORA_ERR_OPTYP$    := 'E';
            END LOOP;
        WHEN OTHERS THEN
            RAISE;
        END;

        -- calculate inserted rows
        idx := rows_to_insert.FIRST;
        WHILE (idx IS NOT NULL) LOOP
            IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
                rows_inserted#                      := rows_inserted# + 1;
                target_table(idx).ORA_ERR_OPTYP$    := 'I';
            END IF;
            --
            idx := rows_to_insert.NEXT(idx);
        END LOOP;
        --
        tree.log_debug('INSERT DONE', rows_inserted#);

        -- prepare index maps for exceptions
        idx := rows_to_update.FIRST;
        WHILE (idx IS NOT NULL) LOOP
            indexes_update.EXTEND;
            indexes_update(indexes_update.LAST) := idx;
            idx := rows_to_update.NEXT(idx);
        END LOOP;

        -- process rows marked for update
        BEGIN
            FORALL i IN INDICES OF rows_to_update
            UPDATE uploaders t  /** TARGET_TABLE */
            SET /** GENERATE_UPDATE:START(3) */
                t.target_table      = target_table(i).target_table,
                t.target_page_id    = target_table(i).target_page_id,
                t.pre_procedure     = target_table(i).pre_procedure,
                t.post_procedure    = target_table(i).post_procedure,
                t.is_active         = target_table(i).is_active
                /** GENERATE_UPDATE:END */
            WHERE /** GENERATE_WHERE:START(3) */
                    t.app_id        = target_table(i).app_id
                AND t.uploader_id   = target_table(i).uploader_id
                ;/** GENERATE_WHERE:END */
        EXCEPTION
        WHEN uploader.forall_failed THEN
            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                idx := indexes_update(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
                --
                rows_errors#                        := rows_errors# + 1;
                target_table(idx).ORA_ERR_MESG$     := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
                target_table(idx).ORA_ERR_OPTYP$    := 'E';
            END LOOP;
        WHEN OTHERS THEN
            RAISE;
        END;

        -- calculate updated rows
        idx := rows_to_update.FIRST;
        WHILE (idx IS NOT NULL) LOOP
            IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
                rows_updated#                       := rows_updated# + 1;
                target_table(idx).ORA_ERR_OPTYP$    := 'U';
            END IF;
            --
            idx := rows_to_update.NEXT(idx);
        END LOOP;
        --
        tree.log_debug('UPDATE DONE', rows_updated#);

        -- rollback changes if not committing changes
        IF in_commit IS NULL THEN
            ROLLBACK TO SAVEPOINT before_merge;
            --
            tree.log_debug('ROLLBACK TO SAVEPOINT');
        END IF;

        --
        -- @TODO: try to evaluate catched errors to get meaningful messages
        --
        NULL;

        -- store uploaded data for further investigations
        DELETE FROM uploaders_u$ t  /** STAGE_TABLE */
        WHERE t.ORA_ERR_TAG$ = TO_CHAR(sess.get_session_id());
        --
        FORALL i IN 1 .. target_table.COUNT
        INSERT INTO uploaders_u$ VALUES target_table(i);  /** STAGE_TABLE */
        --
        UPDATE uploaders_u$ t  /** STAGE_TABLE */
        SET t.ORA_ERR_OPTYP$        = '-'
        WHERE t.ORA_ERR_TAG$        = TO_CHAR(sess.get_session_id())
            AND (t.ORA_ERR_OPTYP$   = 'Y'
                OR t.ORA_ERR_OPTYP$ IS NULL
            );

        -- store results
        UPDATE uploaded_file_sheets s
        SET s.uploader_id       = in_uploader_id,
            s.result_inserted   = rows_inserted#,
            s.result_updated    = rows_updated#,
            s.result_deleted    = rows_deleted#,
            s.result_errors     = rows_errors#,
            s.result_unmatched  = s.sheet_rows - rows_inserted# - rows_updated# - rows_deleted# - rows_errors#,
            s.result_log_id     = module_id,
            --
            s.commited_by       = CASE WHEN in_commit = 'Y' THEN in_user_id END,
            s.commited_at       = CASE WHEN in_commit = 'Y' THEN in_sysdate END
        WHERE s.file_name       = in_file_name
            AND s.sheet_id      = in_sheet_id;
        --
        tree.log_result (
            'ROWS: ' || TO_CHAR(target_table.COUNT) ||
            CASE WHEN rows_inserted# > 0 THEN ', INSERTED: ' || rows_inserted# END ||
            CASE WHEN rows_updated#  > 0 THEN ', UPDATED: '  || rows_updated#  END ||
            CASE WHEN rows_deleted#  > 0 THEN ', DELETED: '  || rows_deleted#  END ||
            CASE WHEN rows_errors#   > 0 THEN ', ERRORS: '   || rows_errors#   END
        );
        --
        tree.update_timer(module_id);
        --
        COMMIT;
    EXCEPTION
    WHEN tree.app_exception THEN
        ROLLBACK;
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        tree.raise_error();
    END;



    FUNCTION generate_columns (
        in_uploader_id          uploaders.uploader_id%TYPE,
        in_type                 VARCHAR2,
        in_indentation          PLS_INTEGER                     := NULL
    )
    RETURN VARCHAR2 AS
        out_                    VARCHAR2(32767);
    BEGIN
        tree.log_module(in_uploader_id, in_type, in_indentation);
        --
        FOR c IN (
            SELECT
                ROW_NUMBER()    OVER(ORDER BY d.column_id)  AS r#,
                COUNT(*)        OVER()                      AS r#_max,
                --
                CASE
                    WHEN in_type = 'INSERT'
                        THEN LOWER(d.column_name)
                    WHEN in_type = 'VALUES'
                        THEN 'target_table(i).' || LOWER(d.column_name)
                    WHEN in_type IN ('UPDATE', 'WHERE')
                        THEN RPAD('t.' || LOWER(d.column_name), CEIL((d.name_length + 5) * 4) / 4) || ' = target_table(i).' || LOWER(d.column_name)
                    END AS text_
            FROM p951_table_columns d
            JOIN uploaders u
                ON u.target_table       = d.table_name
            JOIN uploaders_mapping m
                ON m.uploader_id        = u.uploader_id
                AND m.target_column     = d.column_name
            WHERE u.uploader_id         = in_uploader_id
                AND NVL(m.is_key, '-')  = CASE WHEN in_type = 'WHERE' THEN 'Y' ELSE NVL(m.is_key, '-') END
            ORDER BY d.column_id
        ) LOOP
            out_ := out_ ||
                CASE WHEN in_indentation > 0
                    THEN RPAD(' ', 4 * NVL(in_indentation, 0), ' ') END ||
                CASE WHEN in_type = 'WHERE'
                    THEN CASE WHEN c.r# = 1 THEN '    ' ELSE 'AND ' END
                    END ||
                c.text_ ||
                CASE WHEN in_type != 'WHERE' AND c.r# < c.r#_max THEN ',' END ||
                CHR(10);
        END LOOP;
        --
        tree.update_timer();
        --
        RETURN out_;
    END;



    PROCEDURE generate_procedure (
        in_uploader_id          uploaders.uploader_id%TYPE
    ) AS
        in_template_table       CONSTANT VARCHAR2(30) := 'uploaders';               -- table used in template
        in_target_table         CONSTANT VARCHAR2(30) := LOWER(in_uploader_id);
        --
        skipping_flag           VARCHAR2(64);
        line_                   VARCHAR2(4000);
        out_                    VARCHAR2(32767);
    BEGIN
        tree.log_module(in_uploader_id);
        --
        out_ := 'CREATE OR REPLACE PROCEDURE ' || LOWER(uploader.get_procedure_name(in_uploader_id)) || ' (' || CHR(10);

        -- find template start and end and all lines in between
        FOR c IN (
            WITH start_line AS (
                SELECT s.line
                FROM user_source s
                WHERE s.name        = 'UPLOADER'
                    AND s.type      = 'PACKAGE BODY'
                    AND s.text      LIKE '%PROCEDURE uploader_template%'
            ),
            x AS (
                SELECT
                    MIN(s.line)     AS start_line,
                    MIN(e.line)     AS end_line
                FROM user_source e
                CROSS JOIN start_line s
                WHERE e.name        = 'UPLOADER'
                    AND e.type      = 'PACKAGE BODY'
                    AND e.text      LIKE '    END;%'
                    AND e.line      > s.line
            )
            SELECT s.line, s.text, REGEXP_SUBSTR(s.text, '/\*\*\s?([^*]+)\s?\*/', 1, 1, NULL, 1) AS action
            FROM user_source s
            CROSS JOIN x
            WHERE s.name        = 'UPLOADER'
                AND s.type      = 'PACKAGE BODY'
                AND s.line      BETWEEN x.start_line + 1 AND x.end_line
            ORDER BY s.line
        ) LOOP
            -- stop skipping
            IF skipping_flag IS NOT NULL AND skipping_flag = RTRIM(c.action) THEN
                skipping_flag := NULL;
            END IF;

            -- during skipping
            IF skipping_flag IS NOT NULL THEN
                CONTINUE;
            END IF;

            -- passing line
            IF skipping_flag IS NULL THEN
                -- replace table names
                IF RTRIM(c.action) = 'STAGE_TABLE' THEN
                    c.text := REGEXP_REPLACE(c.text,
                        REPLACE(uploader.get_u$_table_name(in_template_table), '$', '[$]'),
                        uploader.get_u$_table_name(in_target_table),
                        1, 1, 'i'
                    );
                END IF;
                --
                IF RTRIM(c.action) = 'TARGET_TABLE' THEN
                    c.text := REGEXP_REPLACE(c.text, in_template_table, in_target_table, 1, 1, 'i');
                END IF;
                --
                line_   := SUBSTR(c.text, 5, 4000);
                out_    := out_ || REGEXP_REPLACE(line_, '\s+$', '') || CHR(10);
            END IF;

            -- check for start flags
            IF c.action LIKE 'GENERATE_%:START%' THEN
                skipping_flag := REGEXP_REPLACE(c.action, ':START.*$', ':END');
                --
                line_ := uploader.generate_columns (
                    in_uploader_id      => in_uploader_id,
                    in_type             => REGEXP_SUBSTR(c.action, 'GENERATE_([^:]+):', 1, 1, NULL, 1),
                    in_indentation      => REGEXP_SUBSTR(c.action, ':START[(](\d+)[)]', 1, 1, NULL, 1)
                );
                --
                out_ := out_ || REGEXP_REPLACE(line_, '\s+$', '') || CHR(10);
            END IF;
        END LOOP;
        --
        --tree.attach_clob(out_, 'UPLOADER');
        --
        BEGIN
            EXECUTE IMMEDIATE out_;
        EXCEPTION
        WHEN OTHERS THEN
            tree.raise_error('COMPILATION_FAILED');
        END;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    FUNCTION get_cursor_from_query (
        in_query                VARCHAR2
    )
    RETURN SYS_REFCURSOR
    AS
        r SYS_REFCURSOR;
    BEGIN
        OPEN r FOR in_query;
        RETURN r;
    END;



    PROCEDURE update_mapping (
        in_uploader_id          uploaders_mapping.uploader_id%TYPE,
        in_source_column        uploaders_mapping.source_column%TYPE,
        in_target_column        uploaders_mapping.target_column%TYPE,
        in_overwrite_value      uploaders_mapping.overwrite_value%TYPE
    ) AS
    BEGIN
        tree.log_module(in_uploader_id, in_source_column, in_target_column, in_overwrite_value);
        --
        UPDATE uploaders_mapping m
        SET m.source_column         = in_source_column,
            m.overwrite_value       = in_overwrite_value
        WHERE m.app_id              = sess.get_app_id()
            AND m.uploader_id       = in_uploader_id
            AND m.target_column     = in_target_column;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;

END;
/
