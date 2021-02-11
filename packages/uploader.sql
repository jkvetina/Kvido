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

END;
/
