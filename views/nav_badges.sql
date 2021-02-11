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
    ' '                             AS page_alias,
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
    NULL        AS page_id,
    'ENV_NAME'  AS page_alias,
    'DEV'       AS badge
FROM DUAL
WHERE auth.is_developer         = 'Y';
--
COMMENT ON TABLE nav_badges             IS 'View with current badges in top menu';

