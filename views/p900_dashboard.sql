CREATE OR REPLACE FORCE VIEW p900_dashboard AS
WITH x AS (
    SELECT
        c.today,
        c.app_id
    FROM calendar c
    WHERE c.app_id          = sess.get_app_id()
        AND c.today         > TO_CHAR(app.get_date() - 7, 'YYYY-MM-DD')
)
SELECT
    x.today,
    --
    NULLIF(SUM(CASE WHEN l.flag = 'M' THEN 1 ELSE 0 END), 0)    AS modules,
    NULLIF(SUM(CASE WHEN l.flag = 'A' THEN 1 ELSE 0 END), 0)    AS actions,
    NULLIF(SUM(CASE WHEN l.flag = 'D' THEN 1 ELSE 0 END), 0)    AS debugs,
    NULLIF(SUM(CASE WHEN l.flag = 'I' THEN 1 ELSE 0 END), 0)    AS info,
    NULLIF(SUM(CASE WHEN l.flag = 'R' THEN 1 ELSE 0 END), 0)    AS results,
    NULLIF(SUM(CASE WHEN l.flag = 'W' THEN 1 ELSE 0 END), 0)    AS warnings,
    NULLIF(SUM(CASE WHEN l.flag = 'E' THEN 1 ELSE 0 END), 0)    AS errors,
    NULLIF(SUM(CASE WHEN l.flag = 'L' THEN 1 ELSE 0 END), 0)    AS longops,
    NULLIF(SUM(CASE WHEN l.flag = 'S' THEN 1 ELSE 0 END), 0)    AS schedulers,
    --NULLIF(COUNT(b.log_id), 0)                                  AS lobs,
    NULL AS lobs,
    --
    NULLIF(SUM(CASE WHEN l.flag = 'G' THEN 1 ELSE 0 END), 0)    AS triggers,
    NULLIF(SUM(CASE WHEN l.flag = 'P' THEN 1 ELSE 0 END), 0)    AS pages,
    NULLIF(SUM(CASE WHEN l.flag = 'F' THEN 1 ELSE 0 END), 0)    AS forms,
    --
    MAX(s.sessions_)                                            AS sessions_,
    MAX(s.users_)                                               AS users_,
    --
    COUNT(l.log_id)                                             AS total,
    apex.get_icon('fa-trash-o', 'Delete related logs')          AS action
FROM x
JOIN logs l
    ON l.app_id         = x.app_id
    AND l.today         = x.today
--LEFT JOIN logs_lobs b
--    ON b.log_parent     = l.log_id
LEFT JOIN (
    SELECT
        s.today,
        COUNT(s.session_id)                 AS sessions_,
        COUNT(DISTINCT s.user_id)           AS users_
    FROM sessions s
    WHERE s.app_id      = sess.get_app_id()
    GROUP BY s.today
) s
    ON s.today          = l.today
GROUP BY x.today;

