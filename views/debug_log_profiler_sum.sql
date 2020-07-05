CREATE OR REPLACE VIEW debug_log_profiler_sum AS
SELECT
    p.name,
    p.module_name,
    p.module_type,
    p.overload,
    p.total_time,
    ROUND(p.total_time / SUM(p.total_time) OVER() * 100, 2) AS module_perc
FROM (
    SELECT
        p.name,
        m.name              AS module_name,
        m.type              AS module_type,
        m.overload,
        SUM(p.total_time)   AS total_time
    FROM debug_log_profiler p
    LEFT JOIN debug_log_modules m
        ON m.object_name    = p.name
        AND m.object_type   = p.type
        AND p.line          BETWEEN m.start_line AND m.end_line
    WHERE p.total_time      > 0
    GROUP BY p.name, m.name, m.type, m.overload
) p
ORDER BY total_time DESC, p.name, p.module_name, p.overload;

