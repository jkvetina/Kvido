--DROP TABLE logs_lobs PURGE;
CREATE TABLE logs_lobs (
    lob_id              NUMBER          NOT NULL,
    log_id              NUMBER          NOT NULL,
    --
    blob_content        BLOB,
    clob_content        CLOB,
    --
    lob_name            VARCHAR2(255),
    lob_length          NUMBER,
    --
    CONSTRAINT pk_logs_lobs PRIMARY KEY (log_id),
    --
    CONSTRAINT fk_logs_lobs_logs FOREIGN KEY (log_id)
        REFERENCES logs(log_id)
);
--
COMMENT ON TABLE  logs_lobs                  IS 'Large objects storage for LOGS table';
--
COMMENT ON COLUMN logs_lobs.lob_id           IS 'ID to have multiple LOBs attached to single row in LOGS';
COMMENT ON COLUMN logs_lobs.log_id           IS 'Referenced log_id';
COMMENT ON COLUMN logs_lobs.blob_content     IS 'BLOB';
COMMENT ON COLUMN logs_lobs.clob_content     IS 'CLOB';
COMMENT ON COLUMN logs_lobs.lob_name         IS 'LOB name';
COMMENT ON COLUMN logs_lobs.lob_length       IS 'LOB length';

