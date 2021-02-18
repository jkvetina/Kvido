--DROP TABLE uploaded_files CASCADE CONSTRAINTS;
CREATE TABLE uploaded_files (
    file_name           VARCHAR2(255)   CONSTRAINT nn_uploaded_files_file_name      NOT NULL,
    file_size           NUMBER          CONSTRAINT nn_uploaded_files_file_size      NOT NULL,
    mime_type           VARCHAR2(4000)  CONSTRAINT nn_uploaded_files_mime_type      NOT NULL,
    blob_content        BLOB,
    --
    app_id              NUMBER(4)       CONSTRAINT nn_uploaded_files_app_id         NOT NULL,
    uploader_id         VARCHAR2(30),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_uploaded_files
        PRIMARY KEY (file_name),
    --
    CONSTRAINT uq_uploaded_files
        UNIQUE (app_id, session_id, updated_at, file_name),
    --
    CONSTRAINT fk_uploaded_files_session_id
        FOREIGN KEY (session_id)
        REFERENCES sessions (session_id),
    --
    CONSTRAINT fk_uploaded_files_uploader_id
        FOREIGN KEY (app_id, uploader_id)
        REFERENCES uploaders (app_id, uploader_id)
);
--
COMMENT ON TABLE uploaded_files                 IS 'List of uploaded files';
--
COMMENT ON COLUMN uploaded_files.file_name      IS 'Unique file ID (folder/original_filename';
COMMENT ON COLUMN uploaded_files.file_size      IS 'File size in bytes';
COMMENT ON COLUMN uploaded_files.mime_type      IS 'Mime type of file';
COMMENT ON COLUMN uploaded_files.blob_content   IS 'File content (binary)';
--
COMMENT ON COLUMN uploaded_files.app_id         IS 'APEX application ID';
COMMENT ON COLUMN uploaded_files.uploader_id    IS 'Uploader ID from Uploaders table';

