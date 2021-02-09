CREATE OR REPLACE FORCE VIEW p902_sessions AS
WITH r AS (
    SELECT
        l.session_id,
        COUNT(*)            AS logs_
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
    GROUP BY l.session_id
)
SELECT
    s.app_id,
    TO_CHAR(s.updated_at, 'YYYY-MM-DD') AS today,
    --
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
    '<span class="fa fa-external-link" title="Open same page with same global items"></span>'   AS redirect_,
    '<span class="fa fa-trash-o" title="Delete session and logs"></span>'                       AS delete_
FROM sessions s
LEFT JOIN r
    ON r.session_id     = s.session_id
WHERE s.app_id          = sess.get_app_id()
    AND s.session_id    = NVL(apex.get_item('P902_SESSION_ID'), s.session_id)
    AND s.user_id       = NVL(apex.get_item('P902_USER_ID'),    s.user_id);
