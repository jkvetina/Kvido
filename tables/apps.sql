--DROP TABLE apps CASCADE CONSTRAINTS;
CREATE TABLE apps (
    app_id              NUMBER(4)       NOT NULL,
    --
    app_name            VARCHAR2(32),
    is_active           CHAR(1),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_apps
        PRIMARY KEY (app_id),
    --
    CONSTRAINT ch_apps_is_active
        CHECK (is_active = 'Y' OR is_active IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  apps              IS 'List of apps';
--
COMMENT ON COLUMN apps.app_id       IS 'APEX application ID';
--
COMMENT ON COLUMN apps.app_name     IS 'Application name';
COMMENT ON COLUMN apps.is_active    IS 'Flag to deny access to app to users (not developers)';

