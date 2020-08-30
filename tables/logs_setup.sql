--DROP TABLE logs_setup CASCADE CONSTRAINTS PURGE;
CREATE TABLE logs_setup (
    app_id          NUMBER(4)       NOT NULL,
    user_id         VARCHAR2(30)    NOT NULL,
    module_name     VARCHAR2(30)    NOT NULL,
    flag            CHAR(1)         NOT NULL,
    --
    track           CHAR(1)         NOT NULL,
    --
    profiler        CHAR(1)         NOT NULL,
    hprof           CHAR(1)         NOT NULL,
    coverage        CHAR(1)         NOT NULL,
    --
    CONSTRAINT pk_logs_setup PRIMARY KEY (app_id, user_id, module_name, flag),
    --
    CONSTRAINT ch_logs_setup_track     CHECK (track        IN ('Y', 'N')),
    CONSTRAINT ch_logs_setup_prof      CHECK (profiler     IN ('Y', 'N')),
    CONSTRAINT ch_logs_setup_hprof     CHECK (hprof        IN ('Y', 'N')),
    CONSTRAINT ch_logs_setup_cc        CHECK (coverage     IN ('Y', 'N'))
)
ORGANIZATION INDEX;
--
COMMENT ON TABLE  logs_setup                IS 'Define what events will or wont be actually tracked or profiled';
--
COMMENT ON COLUMN logs_setup.app_id         IS 'App ID; 0 for no APEX, -1 for any app';
COMMENT ON COLUMN logs_setup.user_id        IS 'User ID; % for any user';
COMMENT ON COLUMN logs_setup.module_name    IS 'Module name; % for any module';
COMMENT ON COLUMN logs_setup.flag           IS 'Flag to differentiate logs; % for any flag';
COMMENT ON COLUMN logs_setup.track          IS 'Y = track; N = dont track; Y > N';
COMMENT ON COLUMN logs_setup.profiler       IS 'Y = start DBMS_PROFILER';
COMMENT ON COLUMN logs_setup.hprof          IS 'Y = start DBMS_HPROF';
COMMENT ON COLUMN logs_setup.coverage       IS 'Y = start DBMS_PLSQL_CODE_COVERAGE';

