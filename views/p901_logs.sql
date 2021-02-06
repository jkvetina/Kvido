CREATE OR REPLACE FORCE VIEW p901_logs AS
SELECT l.*
FROM logs l
WHERE l.app_id          = sess.get_app_id()
    AND l.log_id        = NVL(apex.get_item('P901_LOG_ID'),     l.log_id)
    AND l.flag          = NVL(apex.get_item('P901_FLAG'),       l.flag)
    AND l.page_id       = NVL(apex.get_item('P901_PAGE_ID'),    l.page_id)
    AND l.user_id       = NVL(apex.get_item('P901_USER_ID'),    l.user_id)
    AND l.session_id    = NVL(apex.get_item('P901_SESSION_ID'), l.session_id)
    AND 1 = CASE
        WHEN apex.get_item('P901_LOG_ID') IS NOT NULL THEN 1
        ELSE (
            CASE WHEN 
                    l.created_at    >= TO_DATE(COALESCE(apex.get_item('P901_TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD')
                AND l.created_at    <  TO_DATE(COALESCE(apex.get_item('P901_TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD') + 1
                THEN 1 END
        ) END;

