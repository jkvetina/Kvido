/*
DROP TABLE sessions     PURGE;
DROP TABLE logs_setup   PURGE;
DROP TABLE user_roles   PURGE;
DROP TABLE users        PURGE;
*/
CREATE TABLE users (
    user_id             VARCHAR2(30)    NOT NULL,
    --
    lang                VARCHAR2(5),
    --
    updated_by          VARCHAR2(30)    NOT NULL,
    updated_at          DATE            NOT NULL,
    --
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    --
    CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by)
        REFERENCES users (user_id)
)
STORAGE (BUFFER_POOL KEEP);
--
CREATE INDEX fk_users_updated_by ON users (updated_by) COMPUTE STATISTICS;
--
COMMENT ON TABLE  users                     IS 'List of users';
--
COMMENT ON COLUMN users.user_id             IS 'User ID';
COMMENT ON COLUMN users.lang                IS 'User language';
COMMENT ON COLUMN users.updated_by          IS 'Recent user who updated row';
COMMENT ON COLUMN users.updated_at          IS 'Timestamp of last update';



--
--
--
INSERT INTO users (user_id, updated_by, updated_at) VALUES ('JKVETINA', 'JKVETINA', SYSDATE);
--
INSERT INTO users (user_id, updated_by, updated_at) VALUES ('USER_A', 'JKVETINA', SYSDATE);
INSERT INTO users (user_id, updated_by, updated_at) VALUES ('USER_B', 'JKVETINA', SYSDATE);
INSERT INTO users (user_id, updated_by, updated_at) VALUES ('USER_C', 'JKVETINA', SYSDATE);
COMMIT;

