CREATE OR REPLACE FORCE VIEW p902_activity_chart AS
WITH x AS (
    SELECT
        LEVEL AS bucket_id,
        app.get_date() + NUMTODSINTERVAL((LEVEL - 1) * 10, 'MINUTE') AS start_at,
        app.get_date() + NUMTODSINTERVAL( LEVEL      * 10, 'MINUTE') AS end_at
    FROM DUAL
    CONNECT BY LEVEL <= (1440 / 10)
),
d AS (
    SELECT
        sess.get_time_bucket(l.created_at, 10)  AS bucket_id,
        l.*
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
        AND l.user_id       = NVL(apex.get_item('$USER_ID'),    l.user_id)
        AND l.page_id       = NVL(apex.get_item('$PAGE_ID'),    l.page_id)
        AND l.session_id    = NVL(apex.get_item('$SESSION_ID'), l.session_id)
        AND l.created_at    >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
),
a AS (
    -- tracked business event #1
    SELECT
        sess.get_time_bucket(a.created_at, 10)  AS bucket_id,
        COUNT(a.created_at)                     AS count_rows
    FROM d a
    WHERE a.flag            = 'E'
    GROUP BY sess.get_time_bucket(a.created_at, 10)
),
b AS (
    -- tracked business event #2
    SELECT
        sess.get_time_bucket(b.created_at, 10)  AS bucket_id,
        COUNT(b.created_at)                     AS count_rows
    FROM d b
    WHERE b.flag            = 'W'
    GROUP BY sess.get_time_bucket(b.created_at, 10)
)
SELECT
    x.bucket_id,
    TO_CHAR(x.start_at, 'HH24:MI')          AS chart_label,
    --
    NULLIF(SUM(CASE WHEN d.flag = 'X' AND d.action_name = 'ON_LOAD_BEFORE_HEADER'   THEN 1 ELSE 0 END), 0) AS count_pages,
    NULLIF(SUM(CASE WHEN d.flag = 'X' AND d.action_name = 'ON_SUBMIT'               THEN 1 ELSE 0 END), 0) AS count_forms,
    --
    NULLIF(COUNT(DISTINCT d.user_id), 0)    AS count_users,
    --
    NULLIF(MAX(a.count_rows), 0)            AS count_errors,
    NULLIF(MAX(b.count_rows), 0)            AS count_warnings
FROM x
LEFT JOIN d
    ON d.bucket_id   = x.bucket_id
LEFT JOIN a
    ON a.bucket_id   = x.bucket_id
LEFT JOIN b
    ON b.bucket_id   = x.bucket_id
--
GROUP BY x.bucket_id, x.start_at;

