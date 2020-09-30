CREATE OR REPLACE VIEW logs_profiler AS
SELECT
    s.name,
    s.type,
    s.line,
    m.module_name,
    m.module_type,
    m.overload,
    d.total_occur,
    d.total_time,
    d.max_time,
    b.block,
    b.col,
    b.covered,
    s.text              AS source_line
FROM plsql_profiler_data d
JOIN plsql_profiler_units u
    ON u.runid          = d.runid
    AND u.unit_number   = d.unit_number
JOIN user_source s
    ON s.name           = u.unit_name
    AND s.type          = u.unit_type
    AND s.line          = d.line#
LEFT JOIN logs_modules m
    ON m.package_name   = s.name
    AND s.type          = 'PACKAGE BODY'
    AND s.line          BETWEEN m.body_start AND m.body_end
LEFT JOIN dbmspcc_units c
    ON  c.name          = s.name
    AND c.type          = s.type
    AND c.run_id        = tree.get_coverage_id()
LEFT JOIN dbmspcc_blocks b
    ON  b.run_id        = c.run_id
    AND b.object_id     = c.object_id
    AND b.line          = s.line
WHERE u.runid           = tree.get_profiler_id()
    AND u.unit_owner    = USER;
--
COMMENT ON COLUMN logs_profiler.name           IS 'Object name';
COMMENT ON COLUMN logs_profiler.type           IS 'Object type';
COMMENT ON COLUMN logs_profiler.line           IS 'Line in source code';
COMMENT ON COLUMN logs_profiler.module_name    IS 'Module name';
COMMENT ON COLUMN logs_profiler.module_type    IS 'Module type (function/procedure)';
COMMENT ON COLUMN logs_profiler.overload       IS 'Overload ID';
COMMENT ON COLUMN logs_profiler.total_occur    IS 'Number of occurences (called lines)';
COMMENT ON COLUMN logs_profiler.total_time     IS 'CPU time spent on module';
COMMENT ON COLUMN logs_profiler.max_time       IS 'Time spent on one iteration';
COMMENT ON COLUMN logs_profiler.block          IS 'Block from coverage';
COMMENT ON COLUMN logs_profiler.col            IS 'Column from source line';
COMMENT ON COLUMN logs_profiler.covered        IS 'Covered flag';
COMMENT ON COLUMN logs_profiler.source_line    IS 'Source line';

