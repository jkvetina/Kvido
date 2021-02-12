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
                file_name, file_size, mime_type, blob_content, session_id, uploader_id
            )
            VALUES (
                c.name,
                DBMS_LOB.GETLENGTH(c.blob_content),
                c.mime_type,
                c.blob_content,
                in_session_id,
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



    PROCEDURE delete_file (
        in_file_name        uploaded_files.file_name%TYPE
    ) AS
    BEGIN
        tree.log_module(in_file_name);
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

END;
/
