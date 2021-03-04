CREATE OR REPLACE FORCE VIEW p902_activity_chart_src AS
WITH x AS (
    SELECT
        c.today,
        c.today__,
        c.app_id,
        apex.get_item('$USER_ID')                   AS user_id,
        TO_NUMBER(apex.get_item('$SESSION_ID'))     AS session_id,
        TO_NUMBER(apex.get_item('$PAGE_ID'))        AS page_id
    FROM calendar c
    WHERE c.app_id          = sess.get_app_id()
        AND c.today         = app.get_date_str()
),
z AS (
    SELECT
        LEVEL                                                   AS bucket_id,
        x.today__ + NUMTODSINTERVAL((LEVEL - 1) * 10, 'MINUTE') AS start_at,
        x.today__ + NUMTODSINTERVAL( LEVEL      * 10, 'MINUTE') AS end_at
    FROM x
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
    JOIN x
        ON x.today          = l.today
        AND x.app_id        = l.app_id
    WHERE (l.user_id        = x.user_id         OR x.user_id        IS NULL)
        AND (l.session_id   = x.session_id      OR x.session_id     IS NULL)
        AND (l.page_id      = x.page_id         OR x.page_id        IS NULL)
)
--
SELECT
    z.bucket_id,
    TO_CHAR(z.start_at, 'HH24:MI')                              AS chart_label,
    --
    NULLIF(SUM(CASE WHEN l.flag = 'P' THEN 1 ELSE 0 END), 0)    AS count_pages,
    NULLIF(SUM(CASE WHEN l.flag = 'F' THEN 1 ELSE 0 END), 0)    AS count_forms,
    --
    NULLIF(COUNT(DISTINCT l.user_id), 0)                        AS count_users,
    --
    NULL AS count_business#1,
    NULL AS count_business#2
FROM z
LEFT JOIN l
    ON l.bucket_id = z.bucket_id
GROUP BY z.bucket_id, TO_CHAR(z.start_at, 'HH24:MI');

