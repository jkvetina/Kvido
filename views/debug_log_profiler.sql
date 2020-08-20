CREATE OR REPLACE VIEW debug_log_profiler AS
WITH x AS (
    SELECT
        MAX(CASE e.action_name WHEN 'START_PROFILER' THEN TO_NUMBER(e.arguments) END) AS profiler_id,
        MAX(CASE e.action_name WHEN 'START_COVERAGE' THEN TO_NUMBER(e.arguments) END) AS coverage_id
    FROM (
        SELECT e.action_name, e.flag, e.arguments
        FROM debug_log e
        CONNECT BY PRIOR e.log_id   = e.log_parent
        START WITH e.log_id         = bug.get_tree_id()
    ) e
    WHERE e.flag = 'P'  -- bug.flag_profiler
)
SELECT
    s.name,
    s.type,
    s.line,
    m.module_name,
    m.module_type,
    m.overload,
    d.total_occur       AS total_calls,
    d.total_time,
    d.max_time,
    b.block,
    b.col,
    b.covered,
    s.text              AS source_line,
    x.profiler_id,
    x.coverage_id
FROM plsql_profiler_units p
JOIN plsql_profiler_data d
    ON p.runid          = d.runid
    AND p.unit_number   = d.unit_number
JOIN user_source s
    ON s.name           = p.unit_name
    AND s.type          = p.unit_type
    AND s.line          = d.line#
CROSS JOIN x
LEFT JOIN debug_log_modules m
    ON m.package_name   = s.name
    AND s.type          = 'PACKAGE BODY'
    AND s.line          BETWEEN m.body_start AND m.body_end
LEFT JOIN dbmspcc_units c
    ON  c.name          = s.name
    AND c.type          = s.type
    AND c.run_id        = x.coverage_id
LEFT JOIN dbmspcc_blocks b
    ON  b.run_id        = c.run_id
    AND b.object_id     = c.object_id
    AND b.line          = s.line
WHERE p.runid           = x.profiler_id
    AND p.unit_owner    = USER;
--
COMMENT ON COLUMN debug_log_profiler.name           IS 'Object name';
COMMENT ON COLUMN debug_log_profiler.type           IS 'Object type';
COMMENT ON COLUMN debug_log_profiler.line           IS 'Line in source code';
COMMENT ON COLUMN debug_log_profiler.total_calls    IS 'Number of occurences/calls';
COMMENT ON COLUMN debug_log_profiler.total_time     IS 'Time spent on module';
COMMENT ON COLUMN debug_log_profiler.max_time       IS 'Time spent on one iteration';
COMMENT ON COLUMN debug_log_profiler.block          IS 'Block from coverage';
COMMENT ON COLUMN debug_log_profiler.col            IS 'Column from source line';
COMMENT ON COLUMN debug_log_profiler.covered        IS 'Covered flag';
COMMENT ON COLUMN debug_log_profiler.source_line    IS 'Source line';
COMMENT ON COLUMN debug_log_profiler.profiler_id    IS 'Profiler ID';
COMMENT ON COLUMN debug_log_profiler.coverage_id    IS 'Coverage ID';

