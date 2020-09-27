CREATE OR REPLACE PROCEDURE process_dml_errors (
    in_table_like   VARCHAR2 := '%'
) AS
    --
    -- keep this procedure separated from TREE package
    -- because LOGS_DML_ERRORS view can be invalidated too often
    --
BEGIN
    tree.log_module(in_table_like);
    --
    FOR c IN (
        SELECT
            d.log_id, d.table_name, d.table_rowid, d.action,
            tree.dml_tables_owner || '.' || d.table_name || tree.dml_tables_postfix AS error_table
        FROM logs_dml_errors d
        JOIN logs e
            ON e.log_id     = d.log_id
        WHERE d.table_name  LIKE NVL(UPPER(in_table_like), '%')
    ) LOOP
        tree.process_dml_error (
            in_log_id           => c.log_id,
            in_error_table      => c.error_table,
            in_table_name       => c.table_name,
            in_table_rowid      => c.table_rowid,
            in_action           => c.action
        );
    END LOOP;
END;
/
