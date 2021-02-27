CREATE OR REPLACE FORCE VIEW p901_logs AS
WITH l AS (
    SELECT l.*
    FROM logs l
    WHERE l.created_at      >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
        --
        AND apex.get_item('$LOG_ID')        IS NULL
        AND apex.get_item('$MAX_LOG_ID')    IS NULL
    UNION ALL
    --
    SELECT l.*
    FROM logs l
    WHERE l.log_id = apex.get_item('$LOG_ID')
        AND apex.get_item('$LOG_ID') IS NOT NULL
    UNION ALL
    --
    SELECT l.*
    FROM logs l
    WHERE l.log_id >= TO_NUMBER(apex.get_item('$MAX_LOG_ID'))
        AND apex.get_item('$MAX_LOG_ID') IS NOT NULL
)
SELECT l.*
FROM l
WHERE l.app_id          = sess.get_app_id()
    AND l.user_id       = NVL(apex.get_item('$USER_ID'),        l.user_id)
    AND l.page_id       = NVL(apex.get_item('$PAGE_ID'),        l.page_id)
    AND l.flag          = NVL(apex.get_item('$FLAG'),           l.flag)
    AND l.action_name   = NVL(apex.get_item('$ACTION'),         l.action_name)
    AND l.module_name   = NVL(apex.get_item('$MODULE'),         l.module_name)
    AND l.module_line   = NVL(apex.get_item('$MODULE_LINE'),    l.module_line)
    AND l.session_id    = NVL(apex.get_item('$SESSION_ID'),     l.session_id);

