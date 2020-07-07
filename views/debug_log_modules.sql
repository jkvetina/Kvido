CREATE OR REPLACE VIEW debug_log_modules AS
SELECT
    p.object_name AS package_name,
    p.module_name,
    p.module_type,
    p.overload,
    MAX(CASE p.object_type WHEN 'PACKAGE'       THEN p.start_line END)              AS spec_start,
    MAX(CASE p.object_type WHEN 'PACKAGE'       THEN s.line END)                    AS spec_end,
    MAX(CASE p.object_type WHEN 'PACKAGE'       THEN s.line - p.start_line + 1 END) AS spec_lines,
    MAX(CASE p.object_type WHEN 'PACKAGE BODY'  THEN p.start_line END)              AS body_start,
    MAX(CASE p.object_type WHEN 'PACKAGE BODY'  THEN s.line END)                    AS body_end,
    MAX(CASE p.object_type WHEN 'PACKAGE BODY'  THEN s.line - p.start_line + 1 END) AS body_lines
FROM (
    SELECT
        i.object_name,
        i.object_type,
        i.name          AS module_name,
        i.type          AS module_type,
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
) p
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
        (s.type = 'PACKAGE BODY' AND REGEXP_LIKE(UPPER(s.text), '^\s*END(\s+' || p.module_name || ')?\s*;')) OR
        (s.type = 'PACKAGE'      AND REGEXP_LIKE(UPPER(s.text), ';'))
    )
GROUP BY p.object_name, p.module_name, p.module_type, p.overload
ORDER BY p.object_name, MIN(p.start_line);
--
COMMENT ON TABLE debug_log_modules IS 'Find package modules (procedures and functions) and their boundaries (start-end lines)';
--
COMMENT ON COLUMN debug_log_modules.package_name    IS 'Package name';
COMMENT ON COLUMN debug_log_modules.module_name     IS 'Module name';
COMMENT ON COLUMN debug_log_modules.module_type     IS 'Module type';
COMMENT ON COLUMN debug_log_modules.overload        IS 'Overload ID';
COMMENT ON COLUMN debug_log_modules.spec_start      IS 'Module start in specification';
COMMENT ON COLUMN debug_log_modules.spec_end        IS 'Module end in specification';
COMMENT ON COLUMN debug_log_modules.spec_lines      IS 'Lines in specification';
COMMENT ON COLUMN debug_log_modules.body_start      IS 'Module start in body';
COMMENT ON COLUMN debug_log_modules.body_end        IS 'Module end in body';
COMMENT ON COLUMN debug_log_modules.body_lines      IS 'Lines in body';

