CREATE OR REPLACE VIEW p900_activity_chart AS
WITH x AS (
    SELECT
        LEVEL AS group_id,
        TRUNC(SYSDATE) + NUMTODSINTERVAL((LEVEL - 1) * 15, 'MINUTE') AS start_at,
        TRUNC(SYSDATE) + NUMTODSINTERVAL( LEVEL      * 15, 'MINUTE') AS end_at
    FROM DUAL
    CONNECT BY LEVEL <= (1440 / 15)
),
d AS (
    SELECT x.group_id, l.*
    FROM logs l
    JOIN x
        ON l.created_at     >= x.start_at
        AND l.created_at    < x.end_at
    WHERE l.app_id          = sess.get_app_id()
),
a AS (
    -- tracked business event #1
    SELECT x.group_id, COUNT(a.created_at) AS count_rows
    FROM d a
    JOIN x
        ON a.created_at     >= x.start_at
        AND a.created_at    < x.end_at
    WHERE a.flag            = 'E'
    GROUP BY x.group_id
),
b AS (
    -- tracked business event #2
    SELECT x.group_id, COUNT(b.created_at) AS count_rows
    FROM d b
    JOIN x
        ON b.created_at     >= x.start_at
        AND b.created_at    < x.end_at
    WHERE b.flag            = 'W'
    GROUP BY x.group_id
)
SELECT
    x.group_id,
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
    ON d.group_id   = x.group_id
LEFT JOIN a
    ON a.group_id   = x.group_id
LEFT JOIN b
    ON b.group_id   = x.group_id
--
GROUP BY x.group_id, x.start_at;


