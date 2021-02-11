CREATE OR REPLACE FORCE VIEW p900_dashboard AS
SELECT
    TO_CHAR(l.created_at, 'YYYY-MM-DD')                         AS today,
    NULLIF(SUM(CASE WHEN l.flag = 'M' THEN 1 ELSE 0 END), 0)    AS modules,
    NULLIF(SUM(CASE WHEN l.flag = 'A' THEN 1 ELSE 0 END), 0)    AS actions,
    NULLIF(SUM(CASE WHEN l.flag = 'D' THEN 1 ELSE 0 END), 0)    AS debugs,
    NULLIF(SUM(CASE WHEN l.flag = 'I' THEN 1 ELSE 0 END), 0)    AS info,
    NULLIF(SUM(CASE WHEN l.flag = 'R' THEN 1 ELSE 0 END), 0)    AS results,
    NULLIF(SUM(CASE WHEN l.flag = 'W' THEN 1 ELSE 0 END), 0)    AS warnings,
    NULLIF(SUM(CASE WHEN l.flag = 'E' THEN 1 ELSE 0 END), 0)    AS errors,
    NULLIF(SUM(CASE WHEN l.flag = 'L' THEN 1 ELSE 0 END), 0)    AS longops,
    NULLIF(SUM(CASE WHEN l.flag = 'S' THEN 1 ELSE 0 END), 0)    AS schedulers,
    NULLIF(COUNT(b.log_id), 0)                                  AS lobs,
    NULLIF(COUNT(l.log_id), 0)                                  AS total,
    apex.get_icon('fa-trash-o', 'Delete related logs')          AS action
FROM logs l
LEFT JOIN logs_lobs b
    ON b.log_parent     = l.log_id
WHERE l.app_id          = sess.get_app_id()
GROUP BY TO_CHAR(l.created_at, 'YYYY-MM-DD');
