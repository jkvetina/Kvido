CREATE OR REPLACE FORCE VIEW logs_profiler_sum AS
WITH p AS (
    SELECT
        p.name                  AS package_name,
        p.module_name,
        p.module_type,
        p.overload,
        SUM(p.total_occur)      AS total_occur,
        SUM(p.total_time)       AS total_time
    FROM logs_profiler p
    WHERE p.total_time > 0
    GROUP BY p.name, p.module_name, p.module_type, p.overload
),
t AS (
    SELECT
        MAX(CASE e.action_name   WHEN 'STOP_PROFILER'   THEN e.created_at END)
        - MIN(CASE e.action_name WHEN 'START_PROFILER'  THEN e.created_at END) AS timer
    FROM (
        SELECT e.action_name, e.flag, e.arguments, e.created_at
        FROM logs e
        CONNECT BY PRIOR e.log_id   = e.log_parent
        START WITH e.log_id         = tree.get_tree_id()
    ) e
    WHERE e.flag = 'P'--tree.flag_profiler
)
SELECT
    p.package_name,
    p.module_name,
    p.module_type,
    p.overload,
    p.total_occur,
    p.total_time,
    t.timer * (p.total_time / SUM(p.total_time) OVER())     AS module_time,
    ROUND(p.total_time / SUM(p.total_time) OVER() * 100, 2) AS module_perc
FROM p
CROSS JOIN t
UNION ALL
SELECT
    NULL                AS package_name,
    NULL                AS module_name,
    NULL                AS module_type,
    NULL                AS overload,
    SUM(p.total_occur)  AS total_occur,
    SUM(p.total_time)   AS total_time,
    MAX(t.timer)        AS module_time,
    100                 AS module_perc
FROM p
CROSS JOIN t
ORDER BY total_time DESC NULLS FIRST, package_name, module_name, overload;
--
COMMENT ON COLUMN logs_profiler_sum.package_name   IS 'Package name';
COMMENT ON COLUMN logs_profiler_sum.module_name    IS 'Module name';
COMMENT ON COLUMN logs_profiler_sum.module_type    IS 'Module type (function/procedure)';
COMMENT ON COLUMN logs_profiler_sum.overload       IS 'Overload ID';
COMMENT ON COLUMN logs_profiler_sum.total_occur    IS 'Number of occurences (called lines)';
COMMENT ON COLUMN logs_profiler_sum.total_time     IS 'CPU time spent on module';
COMMENT ON COLUMN logs_profiler_sum.module_time    IS 'Real time spent on module';
COMMENT ON COLUMN logs_profiler_sum.module_perc    IS 'Percentage of total time spent on module';

