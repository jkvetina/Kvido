--DROP TABLE logs_setup CASCADE CONSTRAINTS PURGE;
CREATE TABLE logs_setup (
    user_id             VARCHAR2(30),
    app_id              NUMBER(4),
    page_id             NUMBER(6),
    flag                CHAR(1),
    module_name         VARCHAR2(30),
    --
    track               CHAR(1)         NOT NULL,
    profiler            CHAR(1)         NOT NULL,
    --
    CONSTRAINT uq_logs_setup UNIQUE (user_id, app_id, page_id, flag, module_name),
    --
    CONSTRAINT ch_logs_setup_track     CHECK (track        IN ('Y', 'N')),
    CONSTRAINT ch_logs_setup_prof      CHECK (profiler     IN ('Y', 'N')),
    --
    CONSTRAINT ch_logs_setup_prof2     CHECK (
        (profiler = 'N') OR
        (profiler = 'Y' AND track = 'Y')
    )
)
--ORGANIZATION INDEX
;
--
COMMENT ON TABLE  logs_setup                IS 'Define what events will or wont be actually tracked or profiled';
--
COMMENT ON COLUMN logs_setup.user_id        IS 'User ID; `NULL` or `%` for any user';
COMMENT ON COLUMN logs_setup.app_id         IS 'App ID; `0` for no APEX, `NULL` for any app';
COMMENT ON COLUMN logs_setup.page_id        IS 'APEX page ID; `NULL` for any page';
COMMENT ON COLUMN logs_setup.flag           IS 'Flag to differentiate logs; `NULL` for any flag';
COMMENT ON COLUMN logs_setup.module_name    IS 'Module name; `NULL` for any module';
--
COMMENT ON COLUMN logs_setup.track          IS '`Y` = track; `N` = dont track; `Y` > `N`';
COMMENT ON COLUMN logs_setup.profiler       IS '`Y` = start DBMS_PROFILER';

