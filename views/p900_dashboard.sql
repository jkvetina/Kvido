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
    --
    NULLIF(MAX(j.jobs_), 0)                                     AS schedulers,
    NULLIF(MAX(b.lobs_), 0)                                     AS lobs,
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
    ON l.app_id             = x.app_id
    AND l.today             = x.today
LEFT JOIN (
    SELECT
        s.today,
        COUNT(s.session_id)                 AS sessions_,
        COUNT(DISTINCT s.user_id)           AS users_
    FROM sessions s
    WHERE s.app_id          = sess.get_app_id()
    GROUP BY s.today
) s
    ON s.today              = x.today
LEFT JOIN (
    SELECT
        x.today,
        COUNT(d.log_id) AS jobs_
    FROM user_scheduler_job_run_details d
    JOIN x
        ON x.today          = TO_CHAR(d.actual_start_date, 'YYYY-MM-DD')
    GROUP BY x.today
) j
    ON j.today              = x.today
LEFT JOIN (
    SELECT
        x.today,
        COUNT(b.log_id)     AS lobs_
    FROM logs_lobs b
    JOIN logs l
        ON l.log_id         = b.log_parent
    JOIN x
        ON x.app_id         = l.app_id
        AND x.today         = l.today
    GROUP BY x.today
) b
    ON b.today              = x.today
GROUP BY x.today;

