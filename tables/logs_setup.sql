--DROP TABLE logs_setup CASCADE CONSTRAINTS PURGE;
CREATE TABLE logs_setup (
    setup_id            NUMBER,
    --
    app_id              NUMBER(4)       CONSTRAINT nn_logs_setup_app_id         NOT NULL,
    user_id             VARCHAR2(30),
    page_id             NUMBER(6),
    flag                CHAR(1),
    module_name         VARCHAR2(30),
    --
    is_dev              VARCHAR2(1),
    is_debug            VARCHAR2(1),
    --
    is_tracked          CHAR(1)         CONSTRAINT nn_logs_setup_is_tracked     NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_logs_setup
        PRIMARY KEY (setup_id),
    --
    CONSTRAINT uq_logs_setup
        UNIQUE (app_id, user_id, page_id, flag, module_name, is_dev, is_debug),
    --
    CONSTRAINT fk_logs_setup_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),
    --
    CONSTRAINT fk_logs_setup_user_id
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    --
    CONSTRAINT ch_logs_setup_is_dev
        CHECK (is_dev IN ('Y', 'N') OR is_dev IS NULL),
    --
    CONSTRAINT ch_logs_setup_is_debug
        CHECK (is_debug IN ('Y', 'N') OR is_debug IS NULL),
    --
    CONSTRAINT ch_logs_setup_is_tracked
        CHECK (is_tracked IN ('Y', 'N'))
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  logs_setup                IS 'Define what events will or wont be actually tracked or profiled';
--
COMMENT ON COLUMN logs_setup.app_id         IS 'App ID; `0` for no APEX, `NULL` for any app';
COMMENT ON COLUMN logs_setup.page_id        IS 'APEX page ID; `NULL` for any page';
COMMENT ON COLUMN logs_setup.user_id        IS 'User ID; `NULL` for any user';
COMMENT ON COLUMN logs_setup.flag           IS 'Flag to differentiate logs; `NULL` for any flag';
COMMENT ON COLUMN logs_setup.module_name    IS 'Module name; `NULL` for any module';
COMMENT ON COLUMN logs_setup.is_dev         IS 'Developer flag; `Y` for YES, `N` for NO, `NULL` for any';
COMMENT ON COLUMN logs_setup.is_debug       IS 'APEX debug flag; `Y` for YES, `N` for NO, `NULL` for any';
COMMENT ON COLUMN logs_setup.is_tracked     IS '`Y` = track; `N` = dont track; `Y` > `N`';

