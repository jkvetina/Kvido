--DROP TABLE logs_tracking PURGE;
CREATE TABLE logs_tracking (
    user_id         VARCHAR2(30)    NOT NULL,
    module_name     VARCHAR2(30)    NOT NULL,
    flag            CHAR(1)         NOT NULL,
    --
    track           CHAR(1)         NOT NULL,
    --
    CONSTRAINT pk_logs_tracking PRIMARY KEY (user_id, module_name, flag),
    --
    CONSTRAINT ch_logs_tracking_track CHECK (track IN ('Y', 'N'))
)
ORGANIZATION INDEX;
--
COMMENT ON TABLE  logs_tracking                IS 'Define what events will or wont be actually tracked';
--
COMMENT ON COLUMN logs_tracking.user_id        IS 'User ID; % for any user';
COMMENT ON COLUMN logs_tracking.module_name    IS 'Module name; % for any module';
COMMENT ON COLUMN logs_tracking.flag           IS 'Flag used in logs_log; % for any flag';
COMMENT ON COLUMN logs_tracking.track          IS 'Y = track; N = dont track; Y > N';

