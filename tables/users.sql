--DROP TABLE users PURGE;
CREATE TABLE users (
    user_id             VARCHAR2(30)    NOT NULL,
    --
    updated_at          DATE            NOT NULL,
    --
    CONSTRAINT pk_users PRIMARY KEY (user_id)
);
--
COMMENT ON TABLE  users                     IS 'List of users';
--
COMMENT ON COLUMN users.user_id             IS 'User ID';
COMMENT ON COLUMN users.updated_at          IS 'Timestamp of last update';

