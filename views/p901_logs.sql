CREATE OR REPLACE VIEW p901_logs AS
SELECT l.*
FROM logs l
WHERE l.app_id          = sess.get_app_id()
    AND l.log_id        = NVL(apex.get_item('$LOG_ID'),     l.log_id)
    AND l.flag          = NVL(apex.get_item('$FLAG'),       l.flag)
    AND l.page_id       = NVL(apex.get_item('$PAGE_ID'),    l.page_id)
    AND l.user_id       = NVL(apex.get_item('$USER_ID'),    l.user_id)
    AND l.session_id    = NVL(apex.get_item('$SESSION_ID'), l.session_id)
    AND 1 = CASE
        WHEN apex.get_item('$LOG_ID') IS NOT NULL THEN 1
        ELSE (
            CASE WHEN 
                    l.created_at    >= TO_DATE(COALESCE(apex.get_item('$TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD')
                AND l.created_at    <  TO_DATE(COALESCE(apex.get_item('$TODAY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD')), 'YYYY-MM-DD') + 1
                THEN 1 END
        ) END
    AND l.log_id > CASE
        WHEN apex.get_item('$VIEW_NEW_ONLY') = 'Y'
            THEN NVL(TO_NUMBER(apex.get_item('$MAX_LOG_ID')), 0)
        ELSE 0 END;

