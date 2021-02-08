--DROP TABLE navigation_virtuals;
CREATE TABLE navigation_virtuals (
    app_id              NUMBER(4)       NOT NULL,
    page_alias          VARCHAR2(30)    NOT NULL,
    --
    page_name           VARCHAR2(256)   NOT NULL,
    page_target         VARCHAR2(512),              -- html icon, anchor with javascript...
    --
    order#              NUMBER(4),
    css_class           VARCHAR2(64),
    is_hidden           VARCHAR2(1),
    --
    page_group          VARCHAR2(30),               -- visible only sometimes
    auth_scheme         VARCHAR2(30),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_navigation_virtuals
        PRIMARY KEY (app_id, page_alias),
    --
    CONSTRAINT ch_navigation_virtuals_is_hidden
        CHECK (is_hidden = 'Y' OR is_hidden IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  navigation_virtuals               IS 'Virtual pages (most likely just icons in root)';
--
COMMENT ON COLUMN navigation_virtuals.app_id        IS 'APEX application ID';
COMMENT ON COLUMN navigation_virtuals.page_alias    IS 'APEX page alias';


