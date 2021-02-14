--DROP TABLE user_roles PURGE;
CREATE TABLE user_roles (
    app_id              NUMBER(4)       NOT NULL,
    user_id             VARCHAR2(30)    NOT NULL,
    role_id             VARCHAR2(30)    NOT NULL,
    --
    is_active           CHAR(1),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_user_roles
        PRIMARY KEY (app_id, user_id, role_id),
    --
    CONSTRAINT fk_users_roles_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),
    --
    CONSTRAINT fk_users_roles_user_id
        FOREIGN KEY (user_id)
        REFERENCES users (user_id),
    --
    CONSTRAINT fk_users_roles_role_id
        FOREIGN KEY (app_id, role_id)
        REFERENCES roles (app_id, role_id),
    --
    CONSTRAINT ch_user_roles_is_active
        CHECK (is_active = 'Y' OR is_active IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  user_roles                     IS 'List of roles assigned to users';
--
COMMENT ON COLUMN user_roles.app_id              IS 'APEX application ID';
COMMENT ON COLUMN user_roles.user_id             IS 'User ID from `users` table';
COMMENT ON COLUMN user_roles.role_id             IS 'Role ID from `roles` table';
--
COMMENT ON COLUMN user_roles.is_active           IS 'Flag to deactivate user role temporarly';

