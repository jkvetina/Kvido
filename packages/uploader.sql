CREATE OR REPLACE PACKAGE BODY uploader AS

    PROCEDURE upload_file (
        in_session_id       sessions.session_id%TYPE,
        in_file_name        uploaded_files.file_name%TYPE,
        in_target           uploaded_files.uploader_id%TYPE     := NULL
    ) AS
    BEGIN
        tree.log_module(in_session_id, in_file_name, in_target);
        --
        FOR c IN (
            SELECT
                f.name,
                f.blob_content,
                f.mime_type
            FROM apex_application_temp_files f
            WHERE f.name = in_file_name
        ) LOOP
            INSERT INTO uploaded_files (
                file_name, file_size, mime_type, blob_content, uploader_id
            )
            VALUES (
                c.name,
                DBMS_LOB.GETLENGTH(c.blob_content),
                c.mime_type,
                c.blob_content,
                in_target
            );
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
        in_session_id       sessions.session_id%TYPE
    ) AS
        in_uploader_id      CONSTANT uploaders.uploader_id%TYPE := apex.get_item('$TARGET');
        --
        multiple_files      APEX_T_VARCHAR2;
    BEGIN
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
        in_file_name        uploaded_files.file_name%TYPE
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN REGEXP_SUBSTR(in_file_name, '([^/]*)$');
    END;



    PROCEDURE parse_file (
        in_file_name        uploaded_file_sheets.file_name%TYPE,
        in_uploader_id      uploaded_file_sheets.uploader_id%TYPE       := NULL
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
                    p_xlsx_sheet_name   => p.sheet_file_name
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
                    p_file_name         => f.file_name
                )                       AS profile_json
            FROM uploaded_files f
            WHERE f.file_name           = in_file_name
                AND in_file_name        LIKE '%.csv'
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
                JSON_VALUE(c.profile_json, '$."columns".size()'),   -- cols
                JSON_VALUE(c.profile_json, '$."parsed-rows"'),      -- rows
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
        in_file_name        uploaded_file_sheets.file_name%TYPE,
        in_sheet_id         uploaded_file_sheets.sheet_id%TYPE,
        in_uploader_id      uploaded_file_sheets.uploader_id%TYPE,
        in_commit           BOOLEAN                                     := FALSE
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        uploader_procedure  VARCHAR2(30);
    BEGIN
        tree.log_module(in_file_name, in_sheet_id, in_uploader_id, CASE WHEN in_commit THEN 'Y' ELSE 'N' END);
        --
        SAVEPOINT before_merge;

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

tree.log_warning('EXECUTE',
            'BEGIN ' || uploader_procedure || '(' ||
            'in_file_name    => :1, ' ||
            'in_sheet_id     => :2, ' ||
            'in_uploader_id  => :3'   ||
            '); END;',
            in_file_name, 'SHEET:' || in_sheet_id, 'UPL:' || in_uploader_id
);

        -- execute procedure
        EXECUTE IMMEDIATE
            'BEGIN ' || uploader_procedure || '(' ||
            'in_file_name    => :1, ' ||
            'in_sheet_id     => :2, ' ||
            'in_uploader_id  => :3'   ||
            '); END;'
            USING in_file_name, in_sheet_id, in_uploader_id;

        -- commit or rollback changes
        IF NOT in_commit THEN
            ROLLBACK TO SAVEPOINT before_merge;
        ELSE
            COMMIT;
        END IF;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        ROLLBACK;
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        tree.raise_error();
    END;



    PROCEDURE delete_file (
        in_file_name        uploaded_files.file_name%TYPE
    ) AS
        file_exists         CHAR(1) := 'N';
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
        in_file_name        uploaded_files.file_name%TYPE
    ) AS
        out_blob_content    uploaded_files.blob_content%TYPE;
        out_mime_type       uploaded_files.mime_type%TYPE;
    BEGIN
        tree.log_module(in_file_name);
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
        in_uploader_id      uploaders.uploader_id%TYPE
    ) AS
        rec                 uploaders%ROWTYPE;
    BEGIN
        tree.log_module(in_uploader_id);
        --
        SELECT p.table_name, p.page_id
        INTO rec.target_table, rec.target_page_id
        FROM p805_uploaders_possible p
        WHERE p.table_name      = in_uploader_id
            AND p.uploader_id   IS NULL;
        --        
        rec.app_id              := sess.get_app_id();
        rec.uploader_id         := in_uploader_id;
        --
        INSERT INTO uploaders VALUES rec;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE create_uploader_mappings (
        in_uploader_id      uploaders_mapping.uploader_id%TYPE,
        in_clear_current    BOOLEAN                                 := FALSE
    ) AS
        TYPE list_mappings  IS TABLE OF uploaders_mapping%ROWTYPE INDEX BY PLS_INTEGER;
        curr_mappings       list_mappings;
    BEGIN
        tree.log_module(in_uploader_id, CASE WHEN in_clear_current THEN 'Y' END);

        -- store current mappings
        IF NOT in_clear_current THEN
            SELECT m.*
            BULK COLLECT INTO curr_mappings
            FROM uploaders_mapping m
            WHERE m.app_id          = sess.get_app_id()
                AND m.uploader_id   = in_uploader_id;
        END IF;

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
                c.source_column,
                c.overwrite_value
            );
        END LOOP;

        -- set previous values (for some columns)
        IF NOT in_clear_current AND curr_mappings.FIRST IS NOT NULL THEN
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
        END IF;
        --
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    FUNCTION get_dml_err_table_name (
        in_table_name       VARCHAR2
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN in_table_name || uploader.dml_tables_postfix;
    END;



    PROCEDURE rebuild_dml_err_table (
        in_table_name       uploaders.target_table%TYPE
    ) AS
    BEGIN
        --
        -- @TODO: create this as PTT (private temp table) just for current user and transaction
        --
        tree.log_module(in_table_name);

        -- drop table if exists
        BEGIN
            EXECUTE IMMEDIATE
                'DROP TABLE ' || uploader.get_dml_err_table_name(in_table_name) || ' PURGE';
        EXCEPTION
        WHEN OTHERS THEN
            NULL;
        END;

        -- recreate as empty table
        DBMS_ERRLOG.CREATE_ERROR_LOG (
            dml_table_name          => 'DUAL',
            err_log_table_owner     => uploader.dml_tables_owner,
            err_log_table_name      => uploader.get_dml_err_table_name(in_table_name),
            skip_unsupported        => TRUE
        );
        --
        EXECUTE IMMEDIATE
            'ALTER TABLE ' || uploader.get_dml_err_table_name(in_table_name) ||
            ' DROP COLUMN DUMMY';

        -- add numbered columns
        FOR col IN 1 .. uploader.dml_tables_cols LOOP
            EXECUTE IMMEDIATE
                'ALTER TABLE ' || uploader.get_dml_err_table_name(in_table_name) ||
                ' ADD COL' || LPAD(col, 3, '0') || ' VARCHAR2(4000)';
        END LOOP;
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
