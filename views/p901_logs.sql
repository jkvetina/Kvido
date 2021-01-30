CREATE OR REPLACE FORCE VIEW p901_logs AS
SELECT e.*
FROM logs e
WHERE e.app_id          = sess.get_app_id()
    AND e.log_id        = NVL(apex.get_item('P901_LOG_ID'),     e.log_id)
    AND e.flag          = NVL(apex.get_item('P901_FLAG'),       e.flag)
    AND e.page_id       = NVL(apex.get_item('P901_PAGE_ID'),    e.page_id)
    AND e.user_id       = NVL(apex.get_item('P901_USER_ID'),    e.user_id)
    AND e.session_id    = NVL(apex.get_item('P901_SESSION_ID'), e.session_id)
    AND 1 = CASE
        WHEN apex.get_item('P901_LOG_ID') IS NOT NULL THEN 1
        ELSE (
            CASE WHEN 
                    e.created_at    >= TO_DATE(COALESCE(apex.get_item('P901_TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD')
                AND e.created_at    <  TO_DATE(COALESCE(apex.get_item('P901_TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD') + 1
                THEN 1 END
        ) END;

