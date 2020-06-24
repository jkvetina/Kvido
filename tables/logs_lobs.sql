--DROP TABLE debug_log_lobs PURGE;
CREATE TABLE debug_log_lobs (
    log_id              NUMBER          NOT NULL,
    parent_log          NUMBER          NOT NULL,
    --
    lob_name            VARCHAR2(255),
    lob_length          NUMBER,
    --
    blob_content        BLOB,
    clob_content        CLOB,
    --
    CONSTRAINT pk_debug_log_lobs PRIMARY KEY (log_id),
    --
    CONSTRAINT fk_debug_log_lobs_debug_log FOREIGN KEY (parent_log)
        REFERENCES debug_log (log_id)
);
--
COMMENT ON TABLE  debug_log_lobs                  IS 'Large objects storage for LOGS table';
--
COMMENT ON COLUMN debug_log_lobs.log_id           IS 'ID to have multiple LOBs attached to single row in LOGS';
COMMENT ON COLUMN debug_log_lobs.parent_log       IS 'Referenced log_id in LOBS table';
COMMENT ON COLUMN debug_log_lobs.lob_name         IS 'Optional name of the object/file';
COMMENT ON COLUMN debug_log_lobs.lob_length       IS 'Length in bytes';
COMMENT ON COLUMN debug_log_lobs.blob_content     IS 'BLOB';
COMMENT ON COLUMN debug_log_lobs.clob_content     IS 'CLOB';

