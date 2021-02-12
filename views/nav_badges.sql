CREATE OR REPLACE VIEW nav_badges AS
SELECT
    900                             AS page_id,
    ' '                             AS page_alias,
    TO_CHAR(NULLIF(COUNT(*), 0))    AS badge
FROM logs l
WHERE l.created_at          >= TRUNC(SYSDATE)
    AND l.flag              = 'E'
    AND auth.is_developer   = 'Y'
UNION ALL
--
SELECT
    950                             AS page_id,
    ''                              AS page_alias,
    TO_CHAR(NULLIF(COUNT(*), 0))    AS badge
FROM user_objects o
WHERE o.status              != 'VALID'
    AND auth.is_developer   = 'Y'
UNION ALL
--
SELECT
    902                                     AS page_id,
    'sessions'                              AS page_alias,
    TO_CHAR(COUNT(DISTINCT s.session_id))   AS badge
FROM sessions s
WHERE s.updated_at          >= TRUNC(SYSDATE)
    AND auth.is_developer   = 'Y'
UNION ALL
--
SELECT
    901                         AS page_id,
    NULL                        AS page_alias,
    TO_CHAR(COUNT(l.log_id))    AS badge
FROM logs l
WHERE l.created_at              >= TRUNC(SYSDATE)
    AND auth.is_developer       = 'Y'
UNION ALL
--
SELECT
    851                         AS page_id,
    NULL                        AS page_alias,
    TO_CHAR(COUNT(*))           AS badge
FROM uploaded_files u
WHERE (u.app_id, u.session_id, u.updated_at) IN (
    SELECT u.app_id, u.session_id, MAX(u.updated_at) AS updated_at
    FROM uploaded_files u
    WHERE u.app_id          = sess.get_app_id()
        AND u.session_id    = sess.get_session_id()
    GROUP BY u.app_id, u.session_id
);
--
COMMENT ON TABLE nav_badges                 IS 'View with current badges in top menu';
--
COMMENT ON COLUMN nav_badges.page_id        IS 'Page ID with badge';
COMMENT ON COLUMN nav_badges.page_alias     IS 'Page alias when page has no ID and need badge';
COMMENT ON COLUMN nav_badges.badge          IS 'Badge value (string)';

