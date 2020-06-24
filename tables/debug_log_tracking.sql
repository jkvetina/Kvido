--DROP TABLE debug_log_tracking PURGE;
CREATE TABLE debug_log_tracking (
    user_id         VARCHAR2(30)    NOT NULL,
    module_name     VARCHAR2(30)    NOT NULL,
    flag            CHAR(1)         NOT NULL,
    --
    track           CHAR(1)         NOT NULL,
    --
    CONSTRAINT pk_debug_log_tracking PRIMARY KEY (user_id, module_name, flag),
    --
    CONSTRAINT ch_debug_log_tracking_track CHECK (track IN ('Y', 'N'))
)
ORGANIZATION INDEX;
--
COMMENT ON TABLE  debug_log_tracking                IS 'Define what events will or wont be actually tracked';
--
COMMENT ON COLUMN debug_log_tracking.user_id        IS 'User ID; % for any user';
COMMENT ON COLUMN debug_log_tracking.module_name    IS 'Module name in LOGS table; % for any module';
COMMENT ON COLUMN debug_log_tracking.flag           IS 'Flag used in LOGS table; % for any flag';
COMMENT ON COLUMN debug_log_tracking.track          IS 'Y = track; N = dont track; Y > N';

