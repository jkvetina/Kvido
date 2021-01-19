--DROP TABLE roles PURGE;
CREATE TABLE roles (
    role_id             VARCHAR2(30)    NOT NULL,
    --
    description_        VARCHAR2(1000),
    --
    CONSTRAINT pk_roles PRIMARY KEY (role_id)
);
--
COMMENT ON TABLE  roles                     IS 'List of roles';
--
COMMENT ON COLUMN roles.role_id             IS 'Role ID';
COMMENT ON COLUMN roles.description_        IS 'Description';

