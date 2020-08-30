CREATE OR REPLACE VIEW logs_dml_errors (
    log_id, action, table_name, table_rowid, dml_rowid, err_message
) AS
SELECT 0, '-', '-', 'UROWID', ROWID, '-'
FROM DUAL
--
-- THIS VIEW IS GENERATED
--
WHERE ROWNUM = 0;
--
COMMENT ON COLUMN logs_dml_errors.log_id       IS 'Related log_id from logs table';
COMMENT ON COLUMN logs_dml_errors.action       IS 'I, U, D as DML action/operation';
COMMENT ON COLUMN logs_dml_errors.table_name   IS 'Table name where error occured';
COMMENT ON COLUMN logs_dml_errors.table_rowid  IS 'ROWID from target table';
COMMENT ON COLUMN logs_dml_errors.dml_rowid    IS 'ROWID from DML ERR table';
COMMENT ON COLUMN logs_dml_errors.err_message  IS 'Error message';

