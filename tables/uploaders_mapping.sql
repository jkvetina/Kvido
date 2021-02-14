--DROP TABLE uploaders_mapping;
CREATE TABLE uploaders_mapping (
    app_id              NUMBER(4)       NOT NULL,
    uploader_id         VARCHAR2(30)    NOT NULL,
    target_column       VARCHAR2(30)    NOT NULL,
    --
    is_key              CHAR(1),
    is_nn               CHAR(1),
    --
    source_column       VARCHAR2(64),
    overwrite_value     VARCHAR2(256),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_uploaders_mapping
        PRIMARY KEY (app_id, uploader_id, target_column),
    --
    CONSTRAINT fk_uploaders_mapping_uploader_id
        FOREIGN KEY (app_id, uploader_id)
        REFERENCES uploaders (app_id, uploader_id),
    --
    CONSTRAINT ch_uploaders_mapping_is_key
        CHECK (is_key = 'Y' OR is_key IS NULL),
    --
    CONSTRAINT ch_uploaders_mapping_is_nn
        CHECK (is_nn = 'Y' OR is_nn IS NULL),
    --
    CONSTRAINT ch_uploaders_mapping_is_hidden
        CHECK (is_hidden = 'Y' OR is_hidden IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE uploaders_mapping                      IS 'Transformations from source to target columns';
--
COMMENT ON COLUMN uploaders_mapping.app_id              IS 'APEX application ID';
COMMENT ON COLUMN uploaders_mapping.uploader_id         IS 'Uploader ID';
COMMENT ON COLUMN uploaders_mapping.target_column       IS 'Real database column from target table';
--
COMMENT ON COLUMN uploaders_mapping.is_key              IS 'Flag to use column as key (primary key, unique)';
COMMENT ON COLUMN uploaders_mapping.is_nn               IS 'Flag to require value on upload';
--
COMMENT ON COLUMN uploaders_mapping.source_column       IS 'Source column name from uploaded file';
COMMENT ON COLUMN uploaders_mapping.overwrite_value     IS 'Overwrite uploaded value with this';

