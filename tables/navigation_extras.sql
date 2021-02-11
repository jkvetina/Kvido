--DROP TABLE navigation_extras;
CREATE TABLE navigation_extras (
    app_id              NUMBER(4)       NOT NULL,
    page_alias          VARCHAR2(30)    NOT NULL,
    --
    page_name           VARCHAR2(256)   NOT NULL,
    page_title          VARCHAR2(256),
    page_target         VARCHAR2(256),
    page_onclick        VARCHAR2(256),
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
    CONSTRAINT pk_navigation_extras
        PRIMARY KEY (app_id, page_alias),
    --
    CONSTRAINT ch_navigation_extras_is_hidden
        CHECK (is_hidden = 'Y' OR is_hidden IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  navigation_extras                 IS 'Virtual pages (most likely just icons in root)';
--
COMMENT ON COLUMN navigation_extras.app_id          IS 'APEX application ID';
COMMENT ON COLUMN navigation_extras.page_alias      IS 'APEX page alias';
COMMENT ON COLUMN navigation_extras.page_name       IS 'Page name (incl. icons)';
COMMENT ON COLUMN navigation_extras.page_title      IS 'Title for bubble tips';
COMMENT ON COLUMN navigation_extras.page_target     IS 'Overload target';
COMMENT ON COLUMN navigation_extras.page_onclick    IS 'Javascript action';

