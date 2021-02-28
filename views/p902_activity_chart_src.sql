CREATE OR REPLACE FORCE VIEW p902_activity_chart_src AS
WITH x AS (
    SELECT
        LEVEL AS bucket_id,
        app.get_date() + NUMTODSINTERVAL((LEVEL - 1) * 10, 'MINUTE') AS start_at,
        app.get_date() + NUMTODSINTERVAL( LEVEL      * 10, 'MINUTE') AS end_at
    FROM DUAL
    CONNECT BY LEVEL <= (1440 / 10)
),
l AS (
    SELECT
        sess.get_time_bucket(l.created_at, 10) AS bucket_id,
        l.log_id,
        l.flag,
        l.user_id,
        l.page_id,
        l.session_id
    FROM logs l
    WHERE l.created_at     >= app.get_date()
        AND l.created_at    < app.get_date() + 1
        AND l.app_id        = sess.get_app_id()
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
)
--
SELECT
    x.bucket_id,
    TO_CHAR(x.start_at, 'HH24:MI')                              AS chart_label,
    --
    NULLIF(SUM(CASE WHEN l.flag = 'P' THEN 1 ELSE 0 END), 0)    AS count_pages,
    NULLIF(SUM(CASE WHEN l.flag = 'F' THEN 1 ELSE 0 END), 0)    AS count_forms,
    --
    NULLIF(COUNT(DISTINCT l.user_id), 0)                        AS count_users,
    --
    NULL AS count_business#1,
    NULL AS count_business#2
FROM x
LEFT JOIN l
    ON l.bucket_id = x.bucket_id
LEFT JOIN filter_pages p
    ON p.log_id = l.log_id
    AND (
        p.log_id IS NOT NULL
        OR apex.get_item('$PAGE_ID') IS NULL
    )
LEFT JOIN filter_users u
    ON u.log_id = l.log_id
    AND (
        u.log_id IS NOT NULL
        OR apex.get_item('$USER_ID') IS NULL
    )
LEFT JOIN filter_sessions s
    ON s.log_id = l.log_id
    AND (
        s.log_id IS NOT NULL
        OR apex.get_item('$SESSION_ID') IS NULL
    )
GROUP BY x.bucket_id, x.start_at;

