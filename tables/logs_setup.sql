--DROP TABLE logs_setup CASCADE CONSTRAINTS PURGE;
CREATE TABLE logs_setup (
    app_id              NUMBER(4)       CONSTRAINT nn_logs_setup_app_id         NOT NULL,
    user_id             VARCHAR2(30),
    page_id             NUMBER(6),
    flag                CHAR(1),
    module_name         VARCHAR2(30),
    --
    is_tracked          CHAR(1)         CONSTRAINT nn_logs_setup_is_tracked     NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT uq_logs_setup
        UNIQUE (app_id, page_id, user_id, flag, module_name),
    --
    CONSTRAINT fk_logs_setup_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),
    --
    CONSTRAINT fk_logs_setup_user_id
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    --
    CONSTRAINT ch_logs_setup_is_tracked
        CHECK (is_tracked IN ('Y', 'N'))
)
STORAGE (BUFFER_POOL KEEP);
--
CREATE INDEX fk_logs_setup_user_id ON logs_setup (user_id) COMPUTE STATISTICS;
--
COMMENT ON TABLE  logs_setup                IS 'Define what events will or wont be actually tracked or profiled';
--
COMMENT ON COLUMN logs_setup.app_id         IS 'App ID; `0` for no APEX, `NULL` for any app';
COMMENT ON COLUMN logs_setup.page_id        IS 'APEX page ID; `NULL` for any page';
COMMENT ON COLUMN logs_setup.user_id        IS 'User ID; `NULL` or `%` for any user';--
COMMENT ON COLUMN logs_setup.flag           IS 'Flag to differentiate logs; `NULL` for any flag';
COMMENT ON COLUMN logs_setup.module_name    IS 'Module name; `NULL` for any module';
COMMENT ON COLUMN logs_setup.is_tracked     IS '`Y` = track; `N` = dont track; `Y` > `N`';

