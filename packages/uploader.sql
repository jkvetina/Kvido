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
        multiple_files      APEX_T_VARCHAR2;
    BEGIN
        tree.log_module(in_session_id);
        --
        multiple_files := APEX_STRING.SPLIT(apex.get_item('$FILE'), ':');
        FOR i IN 1 .. multiple_files.COUNT LOOP
            tree.log_debug(multiple_files(i));
        END LOOP;
        --
        FOR i IN 1 .. multiple_files.COUNT LOOP
            uploader.upload_file (
                in_session_id   => in_session_id,
                in_file_name    => multiple_files(i),
                in_target       => apex.get_item('$TARGET')
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
