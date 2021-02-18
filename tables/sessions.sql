--DROP TABLE sessions PURGE;
CREATE TABLE sessions (
    session_id          NUMBER          CONSTRAINT nn_sessions_session_id   NOT NULL,
    --
    user_id             VARCHAR2(30)    CONSTRAINT nn_sessions_user_id      NOT NULL,
    app_id              NUMBER(4)       CONSTRAINT nn_sessions_app_id       NOT NULL,       -- FK to apps
    page_id             NUMBER(6)       CONSTRAINT nn_sessions_page_id      NOT NULL,       -- FK to app_pages
    --
    apex_items          VARCHAR2(4000),
    --
    session_db          NUMBER          CONSTRAINT nn_sessions_session_db   NOT NULL,
    --
    created_at          DATE            CONSTRAINT nn_sessions_created_at   NOT NULL,
    updated_at          DATE            CONSTRAINT nn_sessions_updated_at   NOT NULL,
    --
    CONSTRAINT pk_sessions
        PRIMARY KEY (session_id),
    /**
    SELECT n.table_name, n.constraint_name
    FROM user_constraints n
    WHERE n.r_constraint_name = 'PK_SESSIONS';
    */
    --
    CONSTRAINT fk_sessions_users
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    --
    CONSTRAINT fk_sessions_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),

    CONSTRAINT ch_sessions_apex_items_json
        CHECK (apex_items IS JSON)
)
STORAGE (BUFFER_POOL KEEP);
--
CREATE INDEX fk_sessions_users ON sessions (user_id) COMPUTE STATISTICS;
--
COMMENT ON TABLE  sessions                  IS 'Sessions overview';
--
COMMENT ON COLUMN sessions.session_id       IS 'Session ID generated by APEX, used in `logs.session_id`';
COMMENT ON COLUMN sessions.user_id          IS 'User ID';
COMMENT ON COLUMN sessions.app_id           IS 'APEX application ID';
COMMENT ON COLUMN sessions.page_id          IS 'APEX page ID';
--
COMMENT ON COLUMN sessions.apex_items       IS 'APEX global items';
--
COMMENT ON COLUMN sessions.session_db       IS 'Database session ID';
--
COMMENT ON COLUMN sessions.created_at       IS 'Time of creation';
COMMENT ON COLUMN sessions.updated_at       IS 'Time of last update';

