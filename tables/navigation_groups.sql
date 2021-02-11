--DROP TABLE navigation_groups;
CREATE TABLE navigation_groups (
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6)       NOT NULL,
    page_group          VARCHAR2(30)    NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_navigation_groups
        PRIMARY KEY (app_id, page_id),
    --
    CONSTRAINT fk_navigation_page_id
        FOREIGN KEY (app_id, page_id)
        REFERENCES navigation (app_id, page_id)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  navigation_groups                 IS 'Navigation groups to show extra menu items';
--
COMMENT ON COLUMN navigation_groups.app_id          IS 'APEX application ID';
COMMENT ON COLUMN navigation_groups.page_id         IS 'APEX page ID';
COMMENT ON COLUMN navigation_groups.page_group      IS 'Group name';

