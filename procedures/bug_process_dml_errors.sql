CREATE OR REPLACE PROCEDURE bug_process_dml_errors (
    in_table_like   VARCHAR2 := '%'
) AS
    --
    -- keep this procedure separated from BUG package
    -- because DEBUG_LOG_DML_ERRORS view can be invalidated too often
    --
BEGIN
    FOR c IN (
        SELECT
            e.log_id, e.table_name, e.table_rowid, e.action,
            bug.dml_tables_owner || '.' || e.table_name || bug.dml_tables_postfix AS error_table
        FROM debug_log_dml_errors e
        JOIN debug_log d
            ON d.log_id     = e.log_id
        WHERE e.table_name  LIKE NVL(UPPER(in_table_like), '%')
    ) LOOP
        bug.process_dml_error (
            in_log_id           => c.log_id,
            in_error_table      => c.error_table,
            in_table_name       => c.table_name,
            in_table_rowid      => c.table_rowid,
            in_action           => c.action
        );
    END LOOP;
END;
/
