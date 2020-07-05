--DROP TABLE debug_log_setup CASCADE CONSTRAINTS PURGE;
CREATE TABLE debug_log_setup (
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
    CONSTRAINT pk_debug_log_setup PRIMARY KEY (user_id, module_name, flag),
    --
    CONSTRAINT ch_debug_log_setup_track     CHECK (track        IN ('Y', 'N')),
    CONSTRAINT ch_debug_log_setup_prof      CHECK (profiler     IN ('Y', 'N')),
    CONSTRAINT ch_debug_log_setup_hprof     CHECK (hprof        IN ('Y', 'N')),
    CONSTRAINT ch_debug_log_setup_cc        CHECK (coverage     IN ('Y', 'N'))
)
ORGANIZATION INDEX;
--
COMMENT ON TABLE  debug_log_setup                IS 'Define what events will or wont be actually tracked or profiled';
--
COMMENT ON COLUMN debug_log_setup.user_id        IS 'User ID; % for any user';
COMMENT ON COLUMN debug_log_setup.module_name    IS 'Module name in debug_log table; % for any module';
COMMENT ON COLUMN debug_log_setup.flag           IS 'Flag used in debug_log table; % for any flag';
COMMENT ON COLUMN debug_log_setup.track          IS 'Y = track; N = dont track; Y > N';
COMMENT ON COLUMN debug_log_setup.profiler       IS 'Y = start DBMS_PROFILER';
COMMENT ON COLUMN debug_log_setup.hprof          IS 'Y = start DBMS_HPROF';
COMMENT ON COLUMN debug_log_setup.coverage       IS 'Y = start DBMS_PLSQL_CODE_COVERAGE';

