--DROP TABLE uploaded_file_cols;
CREATE TABLE uploaded_file_cols (
    file_name           VARCHAR2(255)   CONSTRAINT nn_uploaded_file_cols_file_name      NOT NULL,
    sheet_id            NUMBER(4)       CONSTRAINT nn_uploaded_file_cols_sheet_id       NOT NULL,
    column_id           NUMBER(4)       CONSTRAINT nn_uploaded_file_cols_column_id      NOT NULL,
    --
    column_name         VARCHAR2(64),
    data_type           VARCHAR2(30),
    format_mask         VARCHAR2(64),
    --
    --updated_by          VARCHAR2(30),
    --updated_at          DATE,
    --
    CONSTRAINT pk_uploaded_file_cols
        PRIMARY KEY (file_name, sheet_id, column_id),
    --
    CONSTRAINT fk_uploaded_file_cols_sheet_id
        FOREIGN KEY (file_name, sheet_id)
        REFERENCES uploaded_file_sheets (file_name, sheet_id)
);

