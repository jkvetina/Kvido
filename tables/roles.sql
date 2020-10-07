--DROP TABLE roles PURGE;
CREATE TABLE roles (
    role_id             VARCHAR2(30)    NOT NULL,
    --
    CONSTRAINT pk_roles PRIMARY KEY (role_id)
);
--
COMMENT ON TABLE  roles                     IS 'List of roles';
--
COMMENT ON COLUMN roles.role_id             IS 'Role ID';

