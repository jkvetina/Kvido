--DROP TABLE uploaders CASCADE CONSTRAINTS;
CREATE TABLE uploaders (
    app_id              NUMBER(4)       NOT NULL,
    uploader_id         VARCHAR2(30)    NOT NULL,
    --
    target_table        VARCHAR2(30)    NOT NULL,
    target_page_id      NUMBER(4)       NOT NULL,
    --
    pre_procedure       VARCHAR2(61),
    post_procedure      VARCHAR2(61),
    is_active           CHAR(1),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_uploaders
        PRIMARY KEY (app_id, uploader_id),
    --
    CONSTRAINT uq_uploaders
        UNIQUE (app_id, uploader_id, target_table, target_page_id),
    --
    CONSTRAINT fk_uploaders_target_page_id
        FOREIGN KEY (app_id, target_page_id)
        REFERENCES navigation (app_id, page_id),
    --
    CONSTRAINT ch_uploaders_is_active
        CHECK (is_active = 'Y' OR is_active IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE uploaders                      IS 'List of tables available to users for upload';
--
COMMENT ON COLUMN uploaders.app_id              IS 'APEX application ID';
COMMENT ON COLUMN uploaders.uploader_id         IS 'Static ID set on target page region, auth_scheme will be checked';
--
COMMENT ON COLUMN uploaders.target_table        IS 'Real database table holding uploaded data';
COMMENT ON COLUMN uploaders.target_page_id      IS 'APEX page ID with grid/report to check uploaded data';
--
COMMENT ON COLUMN uploaders.pre_procedure       IS 'Procedure called before upload';
COMMENT ON COLUMN uploaders.post_procedure      IS 'Procedure called after upload';
COMMENT ON COLUMN uploaders.is_active           IS 'Flag to enable/disable uploader';

