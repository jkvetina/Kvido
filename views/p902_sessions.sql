CREATE OR REPLACE FORCE VIEW p902_sessions AS
SELECT
    s.*,
    TO_CHAR(s.updated_at, 'YYYY-MM-DD') AS today,
    'REDIRECT'                          AS action
FROM sessions s
WHERE s.app_id          = sess.get_app_id()
    AND s.session_id    = NVL(apex.get_item('P902_SESSION_ID'), s.session_id)
    AND s.user_id       = NVL(apex.get_item('P902_USER_ID'),    s.user_id);
