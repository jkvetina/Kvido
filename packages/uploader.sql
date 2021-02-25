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

        -- check for pre processing procedure
        --
        -- @TODO:
        --

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
            'in_uploader_id  => :3'   ||
            '); END;'
            USING in_file_name, in_sheet_id, in_uploader_id;

        -- move data to collections so we can have dynamic report in APEX
        copy_uploaded_data_to_collection(in_uploader_id);

        -- check for post processing procedure
        --
        -- @TODO:
        --

        -- commit or rollback changes
        IF NOT in_commit THEN
            ROLLBACK TO SAVEPOINT before_merge;
        ELSE
            COMMIT;
        END IF;

        -- redirect ???
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



    PROCEDURE copy_uploaded_data_to_collection (
        in_uploader_id      uploaders.uploader_id%TYPE,
        in_header_name      VARCHAR2                    := '$HEADER_'
    ) AS
        in_collection       CONSTANT VARCHAR2(30)       := 'SQL_' || in_uploader_id;
        in_query            CONSTANT VARCHAR2(32767)    := 'SELECT * FROM ' || in_uploader_id || '_u$';  -- real table, not just upl_id
        --
        out_cols            PLS_INTEGER;
        out_cursor          PLS_INTEGER                 := DBMS_SQL.OPEN_CURSOR;
        out_desc            DBMS_SQL.DESC_TAB;
    BEGIN
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
        FOR i IN 1 .. out_desc.COUNT LOOP
            CASE i
                WHEN 1 THEN out_desc(i).col_name := 'Row #';
                WHEN 2 THEN out_desc(i).col_name := 'Error #';
                WHEN 4 THEN out_desc(i).col_name := 'Result';
                ELSE NULL;
                END CASE;
            --
            BEGIN
                apex.set_item (
                    in_name      => in_header_name || LPAD(i, 3, 0),
                    in_value     => out_desc(i).col_name
                    --
                    -- TRANSLATE COLUMN NAME TO SOMETHING MORE HUMAN FRIENDLY
                    --
                );
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            END;
        END LOOP;
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
        err_table_name      uploaders.target_table%TYPE;
    BEGIN
        err_table_name      := uploader.get_dml_err_table_name(in_table_name);
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
        --
        -- @TODO: create this as PTT (private temp table) just for current user and transaction
        --
        DBMS_ERRLOG.CREATE_ERROR_LOG (
            dml_table_name          => in_table_name,
            err_log_table_name      => err_table_name,
            err_log_table_owner     => uploader.dml_tables_owner,
            err_log_table_space     => NULL,
            skip_unsupported        => TRUE
        );
        --
        tree.update_timer();
        --
        recompile();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    PROCEDURE uploader_template (
        in_file_name        uploaded_file_sheets.file_name%TYPE,
        in_sheet_id         uploaded_file_sheets.sheet_id%TYPE,
        in_uploader_id      uploaded_file_sheets.uploader_id%TYPE
    )
    AS
        TYPE target_table_t
            IS TABLE OF     uploaders_u$%ROWTYPE INDEX BY PLS_INTEGER;  /** STAGE_TABLE */
        --
        target_table        target_table_t;
        --
        rows_to_insert      uploader.target_rows_t      := uploader.target_rows_t();
        rows_to_update      uploader.target_rows_t      := uploader.target_rows_t();
        rows_to_delete      uploader.target_rows_t      := uploader.target_rows_t();
        --
        indexes_insert      uploader.target_ids_t       := uploader.target_ids_t();
        indexes_update      uploader.target_ids_t       := uploader.target_ids_t();
        --
        rows_inserted#      SIMPLE_INTEGER := 0;
        rows_updated#       SIMPLE_INTEGER := 0;
        rows_deleted#       SIMPLE_INTEGER := 0;
        rows_errors#        SIMPLE_INTEGER := 0;
        --
        idx                 PLS_INTEGER;
        delete_flag_col     VARCHAR2(30);
    BEGIN
        tree.log_module(in_file_name, in_sheet_id, in_uploader_id);

        -- get delete_flag column name
        BEGIN
            SELECT 'COL' || LPAD(c.column_id, 3, '0') INTO delete_flag_col
            FROM uploaded_file_cols c
            WHERE c.file_name       = in_file_name
                AND c.column_name   = uploader.delete_flag_name;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        END;

        -- bulk collect rows from uploaded file into memory
        SELECT
            p.line_number - 1       AS ORA_ERR_NUMBER$,    -- NUMBER            -- used for row number
            NULL                    AS ORA_ERR_MESG$,      -- VARCHAR2(2000)    -- used for error code
            NULL                    AS ORA_ERR_ROWID$,     -- UROWID
            p.col014                AS ORA_ERR_OPTYP$,     -- VARCHAR2(2)       -- used for delete flag at start, type of operation at the end
            /**
                ^ delete_flag_col
            */
            sess.get_session_id()   AS ORA_ERR_TAG$,       -- VARCHAR2(2000)    -- used for session_id
            --
            /** GENERATE_MAPPINGS:START(2) */
            sess.get_app_id()                       AS app_id,
            NULLIF(p.col002, '[Data Error: N/A]')   AS uploader_id,             -- missing in mappings
            NULLIF(p.col002, '[Data Error: N/A]')   AS target_table,
            NULLIF(p.col007, '[Data Error: N/A]')   AS target_page_id,
            NULLIF(p.col009, '[Data Error: N/A]')   AS pre_procedure,
            NULLIF(p.col010, '[Data Error: N/A]')   AS post_procedure,
            --
            REPLACE(NULLIF(p.col011, '[Data Error: N/A]'), 'Checked', 'Y') AS is_active,
            --
            sess.get_user_id()      AS updated_by,
            SYSDATE                 AS updated_at
            /** GENERATE_MAPPINGS:END */
        BULK COLLECT INTO target_table
        FROM uploaded_files f
        JOIN uploaded_file_sheets s
            ON s.file_name          = f.file_name
            AND s.sheet_id          = in_sheet_id
        CROSS JOIN TABLE(APEX_DATA_PARSER.PARSE(
                p_content           => f.blob_content,
                p_file_name         => f.file_name,
                p_xlsx_sheet_name   => s.sheet_xml_id,                          -- @TODO: fix CSV later
                p_skip_rows         => 1
            )) p
        WHERE f.file_name = in_file_name;

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
            s.result_unmatched  = s.sheet_rows - rows_inserted# - rows_updated# - rows_deleted# - rows_errors#
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
        tree.update_timer();
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END;



    FUNCTION generate_columns (
        in_uploader_id      uploaders.uploader_id%TYPE,
        in_type             VARCHAR2,
        in_indentation      PLS_INTEGER                     := NULL
    )
    RETURN VARCHAR2 AS
        out_                VARCHAR2(32767);
    BEGIN
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
            FROM p805_table_columns d
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
                CASE WHEN in_type IN ('UPDATE', 'WHERE')
                    THEN CASE WHEN c.r# = 1 THEN '    ' ELSE 'AND ' END
                    END ||
                c.text_ ||
                CASE WHEN c.r# < c.r#_max THEN ',' END || CHR(10);
        END LOOP;
        --
        RETURN out_;
    END;



    PROCEDURE generate_procedure (
        in_uploader_id      uploaders.uploader_id%TYPE
    )
    AS
        in_target_table     CONSTANT VARCHAR2(30) := LOWER(in_uploader_id);
        in_template_table   CONSTANT VARCHAR2(30) := 'uploaders';
        in_u$_postfix       CONSTANT VARCHAR2(30) := '_u$';
        --
        skipping_flag       VARCHAR2(64);
        line_               VARCHAR2(4000);
        out_                VARCHAR2(32767);
    BEGIN
        tree.log_module(in_uploader_id);
        --
        FOR c IN (
            WITH start_line AS (
                SELECT s.line
                FROM user_source s
                WHERE s.name        = 'UPLOADER'
                    AND s.type      = 'PACKAGE BODY'
                    AND s.text      LIKE '%uploader_template%'
            ),
            x AS (
                SELECT
                    MAX(s.line)     AS start_line,
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
                    c.text := REPLACE(c.text, in_template_table || in_u$_postfix, in_target_table || in_u$_postfix);
                END IF;
                --
                IF RTRIM(c.action) = 'TARGET_TABLE' THEN
                    c.text := REPLACE(c.text, in_template_table, in_target_table);
                END IF;
                --
                line_   := SUBSTR(c.text, 5, 4000);
                out_    := out_ || REGEXP_REPLACE(line_, '\s+$', '') || CHR(10);
            END IF;

            -- check for start flags
            IF c.action LIKE 'GENERATE_%:START%' THEN
                skipping_flag := REGEXP_REPLACE(c.action, ':START.*$', ':END');
                line_   := uploader.generate_columns (
                    in_uploader_id      => in_uploader_id,
                    in_type             => REGEXP_SUBSTR(c.action, 'GENERATE_([^:]+):', 1, 1, NULL, 1),
                    in_indentation      => REGEXP_SUBSTR(c.action, ':START[(](\d+)[)]', 1, 1, NULL, 1)
                );
                --
                out_    := out_ || REGEXP_REPLACE(line_, '\s+$', '') || CHR(10);
            END IF;
        END LOOP;
        --

--
-- @TODO: EXECUTE IMMEDIATE
--

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE PROCEDURE ... AS');
        DBMS_OUTPUT.PUT_LINE(out_);
        DBMS_OUTPUT.PUT_LINE('/');
        DBMS_OUTPUT.PUT_LINE('');
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
