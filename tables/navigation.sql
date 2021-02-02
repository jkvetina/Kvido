CREATE TABLE navigation (
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6)       NOT NULL,
    --
    parent_id           NUMBER(6),
    order#              NUMBER(4),
    --
    label               VARCHAR2(255),
    icon_name           VARCHAR2(64),
    css_class           VARCHAR2(64),
    is_hidden           VARCHAR2(1),
    --
    CONSTRAINT pk_navigation
        PRIMARY KEY (app_id, page_id),
    --
    CONSTRAINT fk_navigation_parent
        FOREIGN KEY (app_id, parent_id)
        REFERENCES navigation (app_id, page_id),
    --
    CONSTRAINT ch_navigation_is_hidden
        CHECK (is_hidden = 'Y' OR is_hidden IS NULL)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  navigation                IS 'Navigation items';
--
COMMENT ON COLUMN navigation.app_id         IS 'APEX application ID';
COMMENT ON COLUMN navigation.page_id        IS 'APEX page ID';
--
COMMENT ON COLUMN navigation.parent_id      IS 'Parent id for tree';
COMMENT ON COLUMN navigation.order#         IS 'Order of siblings';
--
COMMENT ON COLUMN navigation.label          IS 'Label for menu item';
COMMENT ON COLUMN navigation.icon_name      IS 'Icon name from font APEX';
COMMENT ON COLUMN navigation.css_class      IS 'CSS class for menu item (icon_only, icon_left, icon_right...)';
COMMENT ON COLUMN navigation.is_hidden      IS 'Y = dont show in menu';


