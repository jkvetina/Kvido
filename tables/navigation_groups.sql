CREATE TABLE navigation_groups (
    app_id              NUMBER(4)       NOT NULL,
    group_id            VARCHAR2(30)    NOT NULL,
    page_id             NUMBER(6)       NOT NULL,           -- group activated when this page/root is active
    --
    CONSTRAINT pk_navigation_groups
        PRIMARY KEY (app_id, group_id)
);
--
CREATE UNIQUE INDEX uq_navigation_groups ON navigation_groups (app_id, page_id);



CREATE TABLE navigation_groups_map (
    app_id              NUMBER(4)       NOT NULL,
    group_id            VARCHAR2(30)    NOT NULL,           -- if this group is active
    page_id             NUMBER(6)       NOT NULL,           -- then hide this page
    --
    CONSTRAINT pk_navigation_groups_map
        PRIMARY KEY (app_id, group_id, page_id),
    --
    CONSTRAINT fk_navigation_groups_map_group
        FOREIGN KEY (app_id, group_id)
        REFERENCES navigation_groups (app_id, group_id)
);

