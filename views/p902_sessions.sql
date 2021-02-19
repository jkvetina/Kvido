CREATE OR REPLACE FORCE VIEW p902_sessions AS
WITH r AS (
    SELECT
        l.session_id,
        COUNT(*)            AS logs_
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
        AND l.created_at    >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
    GROUP BY l.session_id
)
SELECT
    s.app_id,
    s.session_id,
    s.user_id,
    s.page_id,
    s.apex_items,
    r.logs_,
    s.session_db,
    s.created_at,
    s.updated_at,
    --
    CASE WHEN (s.updated_at - s.created_at) >= 1 THEN '23:59'
        ELSE TO_CHAR(TRUNC(SYSDATE) + (s.updated_at - s.created_at), 'HH24:MI')
        END AS timer,
    --
    apex.get_icon('fa-external-link', 'Open same page with same global items')  AS redirect_,
    apex.get_icon('fa-trash-o',       'Delete session and logs')                AS delete_
FROM sessions s
LEFT JOIN r
    ON r.session_id     = s.session_id
WHERE s.app_id          = sess.get_app_id()
    AND s.session_id    = NVL(apex.get_item('$SESSION_ID'), s.session_id)
    AND s.user_id       = NVL(apex.get_item('$USER_ID'),    s.user_id)
    AND s.updated_at    >= app.get_date()
    AND s.updated_at    <  app.get_date() + 1;

