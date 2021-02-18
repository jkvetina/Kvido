--DROP TABLE logs_events PURGE;
CREATE TABLE logs_events (
    log_id              INTEGER         CONSTRAINT nn_logs_events_log_id        NOT NULL,
    log_parent          INTEGER,
    --
    app_id              NUMBER(4)       CONSTRAINT nn_logs_events_app_id        NOT NULL,
    event_id            VARCHAR2(30)    CONSTRAINT nn_logs_events_event_id      NOT NULL,
    event_value         NUMBER,
    --
    user_id             VARCHAR2(30)    CONSTRAINT nn_logs_events_user_id       NOT NULL,
    page_id             NUMBER(6)       CONSTRAINT nn_logs_events_page_id       NOT NULL,
    session_id          NUMBER          CONSTRAINT nn_logs_events_session_id    NOT NULL,
    --
    created_at          DATE,
    --
    CONSTRAINT pk_logs_events
        PRIMARY KEY (log_id),
    --
    CONSTRAINT fk_logs_events_log_id
        FOREIGN KEY (log_parent)
        REFERENCES logs (log_id),
    --
    CONSTRAINT fk_logs_events_event_id
        FOREIGN KEY (app_id, event_id)
        REFERENCES events (app_id, event_id),
    --
    CONSTRAINT fk_logs_events_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
    --
    -- FK sessions ?
    --
);
--
COMMENT ON TABLE  logs_events                  IS 'Log for business events';
--
COMMENT ON COLUMN logs_events.log_id           IS 'Log ID';
COMMENT ON COLUMN logs_events.log_parent       IS 'Referenced log_id from LOGS table';
--

