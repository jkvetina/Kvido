CREATE OR REPLACE FORCE VIEW logs_tree_extended AS
WITH x AS (
    SELECT
        MIN(t.log_id) AS min_log_id,
        MAX(t.log_id) AS max_log_id
    FROM logs_tree t
)
SELECT l.*
FROM logs_tree l
UNION ALL
SELECT
    l.log_id,
    l.log_parent,
    l.user_id,
    l.app_id,
    l.page_id,
    l.flag,
    l.action_name,
    '    ' || l.module_name     AS module_name,
    l.module_line               AS line,
    l.arguments,
    --
    REGEXP_REPLACE(REGEXP_SUBSTR(
        l.message,
        '(\s'  || USER || '\..*)'),
        '(\s*' || USER || '.TREE.LOG_[A-Z_]+\s+\[\d+\]){1,2}', '') AS message,
    --
    l.session_id,
    app.get_duration(l.timer)   AS timer,
    l.created_at
FROM logs l
LEFT JOIN logs_tree t
    ON t.log_id     = l.log_id
CROSS JOIN x
WHERE l.log_id      BETWEEN x.min_log_id AND x.max_log_id
    AND t.log_id    IS NULL
    AND (l.session_id, l.user_id, l.app_id, l.page_id) IN (
        SELECT l.session_id, l.user_id, l.app_id, l.page_id
        FROM logs_tree e
        WHERE l.log_id = tree.get_tree_id()
    );
--
COMMENT ON TABLE  logs_tree_extended            IS 'All messages extended by skipped rows';

