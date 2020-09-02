--DROP TABLE contexts PURGE;
CREATE TABLE contexts (
    app_id              NUMBER(4)       NOT NULL,
    user_id             VARCHAR2(30)    NOT NULL,
    session_db          NUMBER          NOT NULL,
    session_apex        NUMBER          NOT NULL,
    --
    payload             VARCHAR2(1000),
    updated_at          DATE            NOT NULL,
    --
    CONSTRAINT pk_contexts PRIMARY KEY (app_id, user_id, session_apex, session_db)
    --
    --CONSTRAINT fk_contexts_users FOREIGN KEY (user_id)
    --    REFERENCES users (used_id)
);
--
COMMENT ON TABLE  contexts                  IS 'Context storage';
--
COMMENT ON COLUMN contexts.app_id           IS 'APEX application ID';
COMMENT ON COLUMN contexts.user_id          IS 'User ID';
COMMENT ON COLUMN contexts.session_db       IS 'Database session ID';
COMMENT ON COLUMN contexts.session_apex     IS 'APEX session ID';
COMMENT ON COLUMN contexts.payload          IS 'Payload';
COMMENT ON COLUMN contexts.updated_at       IS 'Timestamp of last update';

