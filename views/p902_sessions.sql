CREATE OR REPLACE FORCE VIEW p902_sessions AS
WITH x AS (
    SELECT
        c.today,
        c.app_id,
        apex.get_item('$USER_ID')                   AS user_id,
        TO_NUMBER(apex.get_item('$SESSION_ID'))     AS session_id
    FROM calendar c
    WHERE c.app_id          = sess.get_app_id()
        AND c.today         = app.get_date_str()
),
l AS (
    SELECT
        l.session_id,
        COUNT(*)                                                    AS logs_,
        --
        NULLIF(SUM(CASE WHEN l.flag = 'P' THEN 1 ELSE 0 END), 0)    AS pages,
        NULLIF(SUM(CASE WHEN l.flag = 'F' THEN 1 ELSE 0 END), 0)    AS forms,
        NULLIF(SUM(CASE WHEN l.flag = 'G' THEN 1 ELSE 0 END), 0)    AS triggers
    FROM logs l
    JOIN x
        ON x.today          = l.today
        AND x.app_id        = l.app_id
    GROUP BY l.session_id
),
s AS (
    SELECT s.*
    FROM sessions s
    JOIN x
        ON x.today          = s.today
        AND x.app_id        = s.app_id
    WHERE (s.user_id        = x.user_id         OR x.user_id        IS NULL)
        AND (s.session_id   = x.session_id      OR x.session_id     IS NULL)
)
SELECT
    s.app_id,
    s.session_id,
    s.user_id,
    s.page_id,
    s.apex_items,
    l.logs_,
    l.pages,
    l.forms,
    l.triggers,
    s.created_at,
    s.updated_at,
    --
    app.get_duration(s.updated_at - s.created_at) AS duration,
    --
    apex.get_icon('fa-external-link', 'Open same page with same global items')  AS redirect_,
    apex.get_icon('fa-trash-o',       'Delete session and logs')                AS delete_
FROM s
JOIN l
    ON l.session_id         = s.session_id;

