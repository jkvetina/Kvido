--DROP TABLE logs_lobs PURGE;
CREATE TABLE logs_lobs (
    log_id              INTEGER         NOT NULL,
    log_parent          INTEGER         NOT NULL,
    --
    lob_name            VARCHAR2(255),
    lob_length          NUMBER,
    --
    payload_blob        BLOB,
    payload_clob        CLOB,
    payload_xml         XMLTYPE,
    payload_json        CLOB,
    --
    CONSTRAINT pk_logs_lobs
        PRIMARY KEY (log_id),
    --
    CONSTRAINT fk_logs_lobs_logs
        FOREIGN KEY (log_parent)
        REFERENCES logs (log_id),
    --
    CONSTRAINT ch_logs_lobs_json
        CHECK (payload_json IS JSON)
);
--
-- STORE INLINE OF POSSIBLE -> ENABLE STORAGE IN ROW, DB_BLOCK_SIZE 8K
--
COMMENT ON TABLE  logs_lobs                  IS 'Large objects storage for LOGS table';
--
COMMENT ON COLUMN logs_lobs.log_id           IS 'ID to have multiple LOBs attached to single row in LOGS';
COMMENT ON COLUMN logs_lobs.log_parent       IS 'Referenced log_id in LOBS table';
COMMENT ON COLUMN logs_lobs.lob_name         IS 'Optional name of the object/file';
COMMENT ON COLUMN logs_lobs.lob_length       IS 'Length in bytes';
COMMENT ON COLUMN logs_lobs.payload_blob     IS 'BLOB payload';
COMMENT ON COLUMN logs_lobs.payload_clob     IS 'CLOB payload';
COMMENT ON COLUMN logs_lobs.payload_xml      IS 'XML payload';
COMMENT ON COLUMN logs_lobs.payload_json     IS 'JSON payload';

-- missing index on log_parent
CREATE INDEX fk_logs_lobs_logs ON logs_lobs (log_parent);

