CREATE OR REPLACE VIEW debug_log_modules AS
WITH p AS (
    SELECT
        i.object_name,
        i.object_type,
        i.name,
        i.type,
        ROW_NUMBER() OVER (PARTITION BY i.object_name, i.object_type, i.name ORDER BY i.line)   AS overload,
        i.line                                                                                  AS start_line,
        LEAD(i.line) OVER (PARTITION BY i.object_name, i.object_type ORDER BY i.line) - 1       AS end_line
    FROM user_identifiers i
    JOIN user_source s
        ON s.name           = i.object_name
        AND s.type          = i.object_type
        AND s.line          = i.line
    WHERE i.type            IN ('PROCEDURE', 'FUNCTION')
        AND i.object_type   IN ('PACKAGE', 'PACKAGE BODY')
        AND i.usage         = CASE s.type WHEN 'PACKAGE BODY' THEN 'DEFINITION' ELSE 'DECLARATION' END
)
SELECT
    p.object_name,
    p.object_type,
    p.name,
    p.type,
    p.overload,
    p.start_line,
    MAX(s.line)                     AS end_line,
    MAX(s.line) - p.start_line + 1  AS lines
FROM p
LEFT JOIN (
    SELECT s.name, s.type, MAX(s.line) - 1 AS last_line
    FROM user_source s
    WHERE s.text        LIKE 'BEGIN%'  -- package block
        AND s.type      IN ('PACKAGE', 'PACKAGE BODY')
    GROUP BY s.name, s.type
) b
    ON b.name   = p.object_name
    AND b.type  = p.object_type
LEFT JOIN user_source s
    ON s.name   = p.object_name
    AND s.type  = p.object_type
    AND s.line  BETWEEN p.start_line AND COALESCE(p.end_line, b.last_line, 999999)
    AND (
        (s.type = 'PACKAGE BODY' AND REGEXP_LIKE(UPPER(s.text), '^\s*END(\s+' || p.name || ')?\s*;')) OR
        (s.type = 'PACKAGE'      AND REGEXP_LIKE(UPPER(s.text), ';'))
    )
GROUP BY p.object_name, p.object_type, p.name, p.type, p.overload, p.start_line, p.end_line
ORDER BY p.object_name, p.object_type, p.start_line;
--
COMMENT ON TABLE debug_log_modules IS 'Find package modules (procedures and functions) and their boundaries (start-end lines)';
--
COMMENT ON COLUMN debug_log_modules.object_name IS 'Object name';
COMMENT ON COLUMN debug_log_modules.object_type IS 'Object type';
COMMENT ON COLUMN debug_log_modules.name        IS 'Module name';
COMMENT ON COLUMN debug_log_modules.type        IS 'Module type';
COMMENT ON COLUMN debug_log_modules.overload    IS 'Overload ID';
COMMENT ON COLUMN debug_log_modules.start_line  IS 'Module start';
COMMENT ON COLUMN debug_log_modules.end_line    IS 'Module end';
COMMENT ON COLUMN debug_log_modules.lines       IS 'Lines';

