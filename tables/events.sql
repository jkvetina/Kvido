--DROP TABLE logs_events PURGE;
--DROP TABLE events PURGE;
CREATE TABLE events (
    app_id              NUMBER(4)       CONSTRAINT nn_events_app_id         NOT NULL,
    event_id            VARCHAR2(30)    CONSTRAINT nn_events_event_id       NOT NULL,
    --
    updated_by          VARCHAR2(30),
    updated_at          DATE,
    --
    CONSTRAINT pk_events
        PRIMARY KEY (app_id, event_id),
    --
    CONSTRAINT fk_events_app_id
        FOREIGN KEY (app_id)
        REFERENCES apps (app_id)
)
STORAGE (BUFFER_POOL KEEP);

