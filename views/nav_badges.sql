CREATE OR REPLACE FORCE VIEW nav_badges AS
SELECT
    900                             AS page_id,
    ' '                             AS page_alias,
    TO_CHAR(NULLIF(COUNT(*), 0))    AS badge
FROM logs l
WHERE l.created_at          >= app.get_date()
    AND l.created_at        <  app.get_date() + 1
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
WHERE s.updated_at          >= app.get_date()
    AND s.updated_at        <  app.get_date() + 1
    AND auth.is_developer   = 'Y'
UNION ALL
--
SELECT
    901                         AS page_id,
    NULL                        AS page_alias,
    TO_CHAR(COUNT(l.log_id))    AS badge
FROM logs l
WHERE l.created_at          >= app.get_date()
    AND l.created_at        <  app.get_date() + 1
    AND auth.is_developer   = 'Y';
--
COMMENT ON TABLE nav_badges                 IS 'View with current badges in top menu';
--
COMMENT ON COLUMN nav_badges.page_id        IS 'Page ID with badge';
COMMENT ON COLUMN nav_badges.page_alias     IS 'Page alias when page has no ID and need badge';
COMMENT ON COLUMN nav_badges.badge          IS 'Badge value (string)';

