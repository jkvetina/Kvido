--DROP TABLE sessions PURGE;
CREATE TABLE sessions (
    session_id          INTEGER         NOT NULL,
    --
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6)       NOT NULL,
    user_id             VARCHAR2(30)    NOT NULL,
    --
    contexts            VARCHAR2(2000),
    apex_globals        VARCHAR2(2000),
    apex_locals         VARCHAR2(2000),
    --
    session_db          NUMBER          NOT NULL,
    session_apex        NUMBER          NOT NULL,
    --
    src                 VARCHAR2(2),                        -- remove later
    created_at          TIMESTAMP       NOT NULL,
    --
    CONSTRAINT pk_sessions PRIMARY KEY (session_id),
    --
    CONSTRAINT uq_sessions UNIQUE (user_id, app_id, page_id, session_apex, session_db, created_at),
    --
    CONSTRAINT fk_sessions_users FOREIGN KEY (user_id)
        REFERENCES users (user_id)
)
PARTITION BY RANGE (created_at)
INTERVAL (NUMTODSINTERVAL(1, 'DAY')) (
    PARTITION P00 VALUES LESS THAN (TIMESTAMP '2020-01-01 00:00:00')
);
--
--ALTER TABLE sessions DISABLE CONSTRAINT fk_sessions_users;
--
COMMENT ON TABLE  sessions                  IS 'Context storage';
--
COMMENT ON COLUMN sessions.session_id       IS 'Session ID used as a reference in `logs.session_id`';
COMMENT ON COLUMN sessions.app_id           IS 'APEX application ID';
COMMENT ON COLUMN sessions.page_id          IS 'APEX page ID';
COMMENT ON COLUMN sessions.user_id          IS 'User ID';
--
COMMENT ON COLUMN sessions.contexts         IS '`SYS_CONTEXT` items';
COMMENT ON COLUMN sessions.apex_globals     IS 'APEX global items';
COMMENT ON COLUMN sessions.apex_locals      IS 'APEX local items';
--
COMMENT ON COLUMN sessions.session_db       IS 'Database session ID';
COMMENT ON COLUMN sessions.session_apex     IS 'APEX session ID';
--
COMMENT ON COLUMN sessions.src              IS 'Caller to identify source of creation';
COMMENT ON COLUMN sessions.created_at       IS 'Timestamp of creation';

