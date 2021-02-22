CREATE OR REPLACE FORCE VIEW logs_tree_extended AS
WITH x AS (
    SELECT
        MIN(t.log_id) AS min_log_id,
        MAX(t.log_id) AS max_log_id
    FROM logs_tree t
)
SELECT e.*
FROM logs_tree e
UNION ALL
SELECT
    e.log_id,
    e.log_parent,
    e.user_id,
    e.app_id,
    e.page_id,
    e.flag,
    e.action_name,
    '    ' || e.module_name     AS module_name,
    e.module_line               AS line,
    e.arguments,
    e.message,
    e.session_id,
    e.timer,
    e.created_at
FROM logs e
LEFT JOIN logs_tree t
    ON t.log_id     = e.log_id
CROSS JOIN x
WHERE e.log_id      BETWEEN x.min_log_id AND x.max_log_id
    AND t.log_id    IS NULL
    AND (e.session_id, e.user_id, e.app_id, e.page_id) IN (
        SELECT e.session_id, e.user_id, e.app_id, e.page_id
        FROM logs_tree e
        WHERE e.log_id = tree.get_tree_id()
    );
--
COMMENT ON TABLE  logs_tree_extended            IS 'All messages extended by skipped rows';

