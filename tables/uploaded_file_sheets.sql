--DROP TABLE uploaded_file_sheets CASCADE CONSTRAINTS;
CREATE TABLE uploaded_file_sheets (
    file_name           VARCHAR2(255)   CONSTRAINT nn_uploaded_file_sheets_file     NOT NULL,
    sheet_id            NUMBER(4)       CONSTRAINT nn_uploaded_file_sheets_sheet    NOT NULL,
    --
    sheet_xml_id        VARCHAR2(256)   CONSTRAINT nn_uploaded_file_sheets_xml_id   NOT NULL,
    sheet_name          VARCHAR2(256),
    sheet_cols          NUMBER(4),
    sheet_rows          NUMBER(8),
    --
    app_id              NUMBER(4)       CONSTRAINT nn_uploaded_file_sheets_app_id   NOT NULL,
    uploader_id         VARCHAR2(30),
    --
    profile_json        CLOB,
    --
    result_inserted     NUMBER(8),
    result_updated      NUMBER(8),
    result_deleted      NUMBER(8),
    result_errors       NUMBER(8),
    result_unmatched    NUMBER(8),
    result_log_id       INTEGER,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    commited_by         VARCHAR2(30),
    commited_at         DATE,
    --
    CONSTRAINT pk_uploaded_file_sheets
        PRIMARY KEY (file_name, sheet_id),
    --
    CONSTRAINT fk_uploaded_file_sheets_file_name
        FOREIGN KEY (file_name)
        REFERENCES uploaded_files (file_name),
    --
    CONSTRAINT fk_uploaded_file_sheets_uploader_id
        FOREIGN KEY (app_id, uploader_id)
        REFERENCES uploaders (app_id, uploader_id),
    --
    CONSTRAINT fk_uploaded_file_sheets_commited_by
        FOREIGN KEY (commited_by)
        REFERENCES users (user_id)
);

