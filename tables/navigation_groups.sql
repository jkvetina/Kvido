--DROP TABLE navigation_groups;
CREATE TABLE navigation_groups (
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6)       NOT NULL,
    page_group          VARCHAR2(30)    NOT NULL,
    --
    CONSTRAINT pk_navigation_groups
        PRIMARY KEY (app_id, page_id)
)
STORAGE (BUFFER_POOL KEEP);
--

