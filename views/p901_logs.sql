CREATE OR REPLACE FORCE VIEW p901_logs AS
WITH x AS (
    SELECT
        c.app_id,
        c.today
    FROM calendar c
    WHERE c.app_id      = sess.get_app_id()
        AND c.today     = app.get_date_str()
),
l AS (
    SELECT l.*
    FROM logs l
    JOIN x
        ON x.app_id     = l.app_id
        AND x.today     = l.today
),
filter_flags AS (
    SELECT l.log_id
    FROM l
    WHERE l.flag = apex.get_item('$FLAG')
        AND apex.get_item('$FLAG') IS NOT NULL
),
filter_users AS (
    SELECT l.log_id
    FROM l
    WHERE l.user_id = apex.get_item('$USER_ID')
        AND apex.get_item('$USER_ID') IS NOT NULL
),
filter_sessions AS (
    SELECT l.log_id
    FROM l
    WHERE l.session_id = TO_NUMBER(apex.get_item('$SESSION_ID'))
        AND apex.get_item('$SESSION_ID') IS NOT NULL
),
filter_pages AS (
    SELECT l.log_id
    FROM l
    WHERE l.page_id = TO_NUMBER(apex.get_item('$PAGE_ID'))
        AND apex.get_item('$PAGE_ID') IS NOT NULL
),
filter_actions AS (
    SELECT l.log_id
    FROM l
    WHERE l.action_name = apex.get_item('$ACTION')
        AND apex.get_item('$ACTION') IS NOT NULL
),
filter_modules AS (
    SELECT l.log_id
    FROM l
    WHERE l.module_name = apex.get_item('$MODULE')
        AND apex.get_item('$MODULE') IS NOT NULL
),
filter_packages AS (
    SELECT l.log_id
    FROM l
    WHERE l.module_name LIKE apex.get_item('$PACKAGE') || '.%'
        AND apex.get_item('$PACKAGE') IS NOT NULL
),
filter_lines AS (
    SELECT l.log_id
    FROM l
    WHERE l.module_line = TO_NUMBER(apex.get_item('$MODULE_LINE'))
        AND apex.get_item('$MODULE_LINE') IS NOT NULL
)
--
SELECT
    l.log_id,
    l.log_parent,
    l.app_id,
    l.user_id,
    l.page_id,
    l.flag,
    l.action_name,
    l.module_name,
    l.module_line,
    l.arguments,
    --
    REGEXP_REPLACE(REGEXP_SUBSTR(
        l.message,
        '(\s'  || USER || '\..*)'),
        '(\s*' || USER || '.TREE.LOG_[A-Z_]+\s+\[\d+\]){1,2}', '') AS message,
    --
    l.session_id,
    app.get_duration(l.timer) AS timer,
    l.created_at,
    l.today
FROM l
LEFT JOIN filter_flags f        ON f.log_id = l.log_id
LEFT JOIN filter_users u        ON u.log_id = l.log_id
LEFT JOIN filter_sessions s     ON s.log_id = l.log_id
LEFT JOIN filter_pages p        ON p.log_id = l.log_id
LEFT JOIN filter_actions a      ON a.log_id = l.log_id
LEFT JOIN filter_modules m      ON m.log_id = l.log_id
LEFT JOIN filter_packages g     ON g.log_id = l.log_id
LEFT JOIN filter_lines i        ON i.log_id = l.log_id
WHERE
    (l.log_id >= apex.get_item('$MAX_LOG_ID') OR apex.get_item('$MAX_LOG_ID') IS NULL)
    --
    AND (f.log_id IS NOT NULL OR apex.get_item('$FLAG')         IS NULL)
    AND (u.log_id IS NOT NULL OR apex.get_item('$USER_ID')      IS NULL)
    AND (s.log_id IS NOT NULL OR apex.get_item('$SESSION_ID')   IS NULL)
    AND (p.log_id IS NOT NULL OR apex.get_item('$PAGE_ID')      IS NULL)
    AND (a.log_id IS NOT NULL OR apex.get_item('$ACTION')       IS NULL)
    AND (m.log_id IS NOT NULL OR apex.get_item('$MODULE')       IS NULL)
    AND (i.log_id IS NOT NULL OR apex.get_item('$MODULE_LINE')  IS NULL)
    AND (g.log_id IS NOT NULL OR apex.get_item('$PACKAGE')      IS NULL);

