CREATE OR REPLACE PACKAGE uploader AS

    PROCEDURE upload_file (
        in_session_id       sessions.session_id%TYPE,
        in_file_name        uploaded_files.file_name%TYPE,
        in_target           uploaded_files.uploader_id%TYPE     := NULL
    );



    PROCEDURE upload_files (
        in_session_id       sessions.session_id%TYPE
    );

END;
/
