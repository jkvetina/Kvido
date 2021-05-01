--DROP TABLE sessions PURGE;
CREATE TABLE sessions (
    session_id          NUMBER          CONSTRAINT nn_sessions_session_id   NOT NULL,
    app_id              NUMBER(4)       CONSTRAINT nn_sessions_app_id       NOT NULL,       -- FK to apps
    --
    user_id             VARCHAR2(30)    CONSTRAINT nn_sessions_user_id      NOT NULL,
    page_id             NUMBER(6)       CONSTRAINT nn_sessions_page_id      NOT NULL,       -- FK to app_pages
    --
    apex_items          VARCHAR2(4000),
    created_at          DATE            CONSTRAINT nn_sessions_created_at   NOT NULL,
    updated_at          DATE            CONSTRAINT nn_sessions_updated_at   NOT NULL,
    log_id              INTEGER,                                                            -- no FK on purpose
    --
    today               VARCHAR2(10)    CONSTRAINT nn_sessions_today        NOT NULL,       -- no FK on purpose
    --
    CONSTRAINT pk_sessions
        PRIMARY KEY (session_id, app_id),
    /**
    SELECT n.table_name, n.constraint_name
    FROM user_constraints n
    WHERE n.r_constraint_name = 'PK_SESSIONS';
    */
    --
    CONSTRAINT fk_sessions_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),
    --
    CONSTRAINT fk_sessions_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    --
    --CONSTRAINT fk_sessions_logs
    --    FOREIGN KEY (log_id)
    --    REFERENCES logs (log_id),
    --
    --CONSTRAINT fk_sessions_today
    --    FOREIGN KEY (app_id, today)
    --    REFERENCES calendar (app_id, today),
    --
    CONSTRAINT ch_sessions_apex_items_json
        CHECK (apex_items IS JSON)
)
STORAGE (BUFFER_POOL KEEP);
--
CREATE INDEX fk_sessions_users      ON sessions (user_id)           COMPUTE STATISTICS;
CREATE INDEX fk_sessions_calendar   ON sessions (app_id, today)     COMPUTE STATISTICS;
--
COMMENT ON TABLE  sessions                  IS 'Sessions overview';
--
COMMENT ON COLUMN sessions.session_id       IS 'Session ID generated by APEX, used in `logs.session_id`';
COMMENT ON COLUMN sessions.app_id           IS 'APEX application ID';
COMMENT ON COLUMN sessions.user_id          IS 'User ID';
COMMENT ON COLUMN sessions.page_id          IS 'APEX page ID';
--
COMMENT ON COLUMN sessions.apex_items       IS 'APEX global items';
COMMENT ON COLUMN sessions.created_at       IS 'Time of creation';
COMMENT ON COLUMN sessions.updated_at       IS 'Time of last update';
COMMENT ON COLUMN sessions.log_id           IS 'Log ID of page request start';
COMMENT ON COLUMN sessions.today            IS 'Date of session for best performance';

