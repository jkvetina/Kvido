--DROP TABLE navigation;
CREATE TABLE navigation (
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6)       NOT NULL,
    --
    parent_id           NUMBER(6),
    order#              NUMBER(4),
    --
    css_class           VARCHAR2(64),
    is_hidden           VARCHAR2(1),
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_navigation
        PRIMARY KEY (app_id, page_id),
    --
    CONSTRAINT fk_navigation_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id),
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
COMMENT ON COLUMN navigation.css_class      IS 'CSS class for menu item (icon_only, icon_left, icon_right...)';
COMMENT ON COLUMN navigation.is_hidden      IS 'Y = dont show in menu';

