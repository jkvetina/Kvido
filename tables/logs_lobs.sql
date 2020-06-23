--DROP TABLE logs_lobs PURGE;
CREATE TABLE logs_lobs (
    log_id              NUMBER          NOT NULL,
    parent_log          NUMBER          NOT NULL,
    --
    lob_name            VARCHAR2(255),
    lob_length          NUMBER,
    --
    blob_content        BLOB,
    clob_content        CLOB,
    --
    CONSTRAINT pk_logs_lobs PRIMARY KEY (log_id),
    --
    CONSTRAINT fk_logs_lobs_logs FOREIGN KEY (parent_log)
        REFERENCES logs (log_id)
);
--
COMMENT ON TABLE  logs_lobs                  IS 'Large objects storage for LOGS table';
--
COMMENT ON COLUMN logs_lobs.log_id           IS 'ID to have multiple LOBs attached to single row in LOGS';
COMMENT ON COLUMN logs_lobs.parent_log       IS 'Referenced log_id in LOBS table';
COMMENT ON COLUMN logs_lobs.lob_name         IS 'Optiona name of the object/file';
COMMENT ON COLUMN logs_lobs.lob_length       IS 'Length in bytes';
COMMENT ON COLUMN logs_lobs.blob_content     IS 'BLOB';
COMMENT ON COLUMN logs_lobs.clob_content     IS 'CLOB';

