--DROP TABLE uploaders_mapping;
CREATE TABLE uploaders_mapping (
    app_id              NUMBER(4)       NOT NULL,
    uploader_id         VARCHAR2(30)    NOT NULL,
    source_column       VARCHAR2(64)    NOT NULL,
    --
    target_column       VARCHAR2(30)    NOT NULL,
    is_mandatory        CHAR(1),
    overwrite_value     VARCHAR2(256),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_uploaders_mapping
        PRIMARY KEY (app_id, uploader_id, source_column),
    --
    CONSTRAINT fk_uploaders_mapping_uploader_id
        FOREIGN KEY (app_id, uploader_id)
        REFERENCES uploaders (app_id, uploader_id)
);
--
COMMENT ON TABLE uploaders_mapping                      IS 'Transformations from source to target columns';
--
COMMENT ON COLUMN uploaders_mapping.app_id              IS 'APEX application ID';
COMMENT ON COLUMN uploaders_mapping.uploader_id         IS 'Uploader ID';
COMMENT ON COLUMN uploaders_mapping.source_column       IS 'Source column name from uploaded file';
--
COMMENT ON COLUMN uploaders_mapping.target_column       IS 'Real database column from target table';
COMMENT ON COLUMN uploaders_mapping.is_mandatory        IS 'Flag to require value on upload';
COMMENT ON COLUMN uploaders_mapping.overwrite_value     IS 'Overwrite uploaded value with this';

