CREATE OR REPLACE FORCE VIEW p901_logs AS
WITH l AS (
    --SELECT /*+ FULL(logs) PARALLER(logs, 2) */ l.*
    SELECT l.*
    FROM logs l
    WHERE l.created_at     >= app.get_date()
        AND l.created_at    < app.get_date() + 1
        AND l.app_id        = sess.get_app_id()
),
filter_flags AS (
    SELECT l.log_id
    FROM l
    WHERE l.flag = apex.get_item('$FLAG')
        AND apex.get_item('$FLAG') IS NOT NULL
),
filter_pages AS (
    SELECT l.log_id
    FROM l
    WHERE l.page_id = TO_NUMBER(apex.get_item('$PAGE_ID'))
        AND apex.get_item('$PAGE_ID') IS NOT NULL
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
filter_lines AS (
    SELECT l.log_id
    FROM l
    WHERE l.module_line = TO_NUMBER(apex.get_item('$MODULE_LINE'))
        AND apex.get_item('$MODULE_LINE') IS NOT NULL
)
--
SELECT l.*
FROM l
LEFT JOIN filter_flags f        ON f.log_id = l.log_id
LEFT JOIN filter_pages p        ON p.log_id = l.log_id
LEFT JOIN filter_users u        ON u.log_id = l.log_id
LEFT JOIN filter_actions a      ON a.log_id = l.log_id
LEFT JOIN filter_modules m      ON m.log_id = l.log_id
LEFT JOIN filter_lines i        ON i.log_id = l.log_id
LEFT JOIN filter_sessions s     ON s.log_id = l.log_id
WHERE
    (l.log_id >= apex.get_item('$MAX_LOG_ID') OR apex.get_item('$MAX_LOG_ID') IS NULL)
    --
    AND (f.log_id IS NOT NULL OR apex.get_item('$FLAG')         IS NULL)
    AND (p.log_id IS NOT NULL OR apex.get_item('$PAGE_ID')      IS NULL)
    AND (u.log_id IS NOT NULL OR apex.get_item('$USER_ID')      IS NULL)
    AND (a.log_id IS NOT NULL OR apex.get_item('$ACTION')       IS NULL)
    AND (m.log_id IS NOT NULL OR apex.get_item('$MODULE')       IS NULL)
    AND (i.log_id IS NOT NULL OR apex.get_item('$MODULE_LINE')  IS NULL)
    AND (s.log_id IS NOT NULL OR apex.get_item('$SESSION_ID')   IS NULL);

