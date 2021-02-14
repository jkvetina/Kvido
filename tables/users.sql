/*
alter table users drop  CONSTRAINT uq_users_user_login;
alter table users add   CONSTRAINT uq_users_user_login UNIQUE (user_login);
--
DROP TABLE logs_lobs    PURGE;
DROP TABLE logs         PURGE;
DROP TABLE logs_setup   PURGE;
DROP TABLE sessions     CASCADE CONSTRAINTS PURGE;
DROP TABLE user_roles   PURGE;
DROP TABLE users        CASCADE CONSTRAINTS PURGE;
--
SELECT * FROM user_constraints WHERE table_name = 'SESSIONS' AND constraint_type = 'R';
*/
CREATE TABLE users (
    user_id             VARCHAR2(30)    NOT NULL,
    user_login          VARCHAR2(128),
    user_name           VARCHAR2(64),
    --
    lang                VARCHAR2(5),
    --
    is_active           CHAR(1),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_users
        PRIMARY KEY (user_id),
    --
    CONSTRAINT fk_users_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES users (user_id)
        DEFERRABLE INITIALLY DEFERRED,
    --
    CONSTRAINT uq_users_user_login
        UNIQUE (user_login),
    --
    CONSTRAINT ch_users_is_active
        CHECK (is_active = 'Y' OR is_active IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
CREATE INDEX fk_users_updated_by ON users (updated_by) COMPUTE STATISTICS;
--
COMMENT ON TABLE  users                     IS 'List of users';
--
COMMENT ON COLUMN users.user_id             IS 'User ID used internally';
COMMENT ON COLUMN users.user_login          IS 'User login used for login into application';
COMMENT ON COLUMN users.user_name           IS 'User name visible in menu';
--
COMMENT ON COLUMN users.lang                IS 'User language';
COMMENT ON COLUMN users.is_active           IS 'Flag to disable user without changing roles';
--
COMMENT ON COLUMN users.updated_by          IS 'Recent user who updated row';
COMMENT ON COLUMN users.updated_at          IS 'Timestamp of last update';

