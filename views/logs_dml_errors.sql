CREATE OR REPLACE FORCE VIEW logs_dml_errors AS
SELECT
    --
    -- THIS VIEW IS REGENERATED LATER
    --
    0           AS log_id,
    '-'         AS action,
    '-'         AS table_name,
    'UROWID'    AS table_rowid,
    ROWID       AS dml_rowid,
    '-'         AS err_message
FROM DUAL
WHERE ROWNUM = 0;
--
COMMENT ON COLUMN logs_dml_errors.log_id       IS 'Related log_id from logs table';
COMMENT ON COLUMN logs_dml_errors.action       IS 'I, U, D as DML action/operation';
COMMENT ON COLUMN logs_dml_errors.table_name   IS 'Table name where error occured';
COMMENT ON COLUMN logs_dml_errors.table_rowid  IS 'ROWID from target table';
COMMENT ON COLUMN logs_dml_errors.dml_rowid    IS 'ROWID from DML ERR table';
COMMENT ON COLUMN logs_dml_errors.err_message  IS 'Error message';

