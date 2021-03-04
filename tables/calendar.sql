--DROP TABLE calendar;
CREATE TABLE calendar (
    app_id              NUMBER(4)       NOT NULL,
    today               VARCHAR2(10)    NOT NULL,
    today__             DATE            NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_calendar
        PRIMARY KEY (app_id, today),
    --
    CONSTRAINT uq_calendar
        UNIQUE (app_id, today, today__)
)
STORAGE (BUFFER_POOL KEEP);
--
COMMENT ON TABLE  calendar                  IS 'Silly table to have partition pruning working with APEX items';
--
COMMENT ON COLUMN calendar.app_id           IS 'APEX application ID';
COMMENT ON COLUMN calendar.today            IS 'Date of session for best performance';

