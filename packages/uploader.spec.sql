CREATE OR REPLACE PACKAGE uploader AS

    PROCEDURE upload_file (
        in_session_id       sessions.session_id%TYPE,
        in_file_name        uploaded_files.file_name%TYPE,
        in_target           uploaded_files.uploader_id%TYPE     := NULL
    );



    PROCEDURE upload_files (
        in_session_id       sessions.session_id%TYPE
    );



    FUNCTION get_basename (
        in_file_name        uploaded_files.file_name%TYPE
    )
    RETURN VARCHAR2;



    PROCEDURE parse_file (
        in_file_name        uploaded_file_sheets.file_name%TYPE,
        in_uploader_id      uploaded_file_sheets.uploader_id%TYPE       := NULL
    );



    PROCEDURE delete_file (
        in_file_name        uploaded_files.file_name%TYPE
    );



    PROCEDURE download_file (
        in_file_name        uploaded_files.file_name%TYPE
    );



    PROCEDURE create_uploader (
        in_uploader_id      uploaders.uploader_id%TYPE
    );



    PROCEDURE create_uploader_mappings (
        in_uploader_id      uploaders_mapping.uploader_id%TYPE,
        in_clear_current    BOOLEAN                                 := FALSE
    );

END;
/
