--DROP MATERIALIZED VIEW logs_modules;
CREATE MATERIALIZED VIEW logs_modules
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
WITH t AS (
    SELECT
        p.object_name AS package_name,
        p.module_name,
        p.module_type,
        CASE WHEN MAX(p.overload) OVER (PARTITION BY p.object_name, p.module_name) > 1 THEN p.overload END AS overload,     -------------------- check NULLS later
        --
        MIN(CASE p.object_type WHEN 'PACKAGE'       THEN p.start_line END)              AS spec_start,
        MIN(CASE p.object_type WHEN 'PACKAGE'       THEN s.line END)                    AS spec_end,
        MIN(CASE p.object_type WHEN 'PACKAGE'       THEN s.line - p.start_line + 1 END) AS spec_lines,
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
),
g AS (
    SELECT
        t.package_name,
        t.module_name,
        t.module_type,
        t.overload,
        LISTAGG(a.argument_name || ' ' || a.in_out, ', ') WITHIN GROUP (ORDER BY a.position) AS args
    FROM t
    JOIN user_arguments a
        ON a.package_name   = t.package_name
        AND a.object_name   = t.module_name
        AND a.overload      = NVL(t.overload, 1)
        AND a.position      > 0
    GROUP BY t.package_name, t.module_name, t.module_type, t.overload
)
SELECT
    t.*,
    CASE WHEN b.text IS NOT NULL THEN 'Y' END AS private,
    a.args_in, a.args_out,
    d.comment_,
    m.group_line,   -- to match with group on wiki
    g.f_id          -- to remove duplicated rows for same functions and procedures
FROM t
LEFT JOIN (
    SELECT
        a.package_name,
        a.object_name                                                                           AS module_name,
        MIN(CASE WHEN a.in_out = 'OUT' AND a.position = 0 THEN 'FUNCTION' ELSE 'PROCEDURE' END) AS module_type,
        a.overload,
        NULLIF(SUM(CASE WHEN a.in_out LIKE 'IN%'  THEN 1 ELSE 0 END), 0)                        AS args_in,
        NULLIF(SUM(CASE WHEN a.in_out LIKE '%OUT' AND position > 0 THEN 1 ELSE 0 END), 0)       AS args_out
    FROM user_arguments a
    GROUP BY a.package_name, a.object_name, a.overload
) a
    ON a.package_name       = t.package_name
    AND a.module_name       = t.module_name
    AND a.module_type       = t.module_type
    AND NVL(a.overload, 1)  = NVL(t.overload, 1)
LEFT JOIN (
    SELECT
        d.package_name, d.module_name, d.module_type, d.overload, --x.line, x.text
        LISTAGG(REGEXP_SUBSTR(x.text, '^\s*--\s*(.*)\s*$', 1, 1, NULL, 1), '<br />') WITHIN GROUP (ORDER BY x.line) AS comment_,
        MIN(x.line) AS doc_start
    FROM (
        SELECT
            t.package_name, t.module_name, t.module_type, t.overload,
            MAX(x.line) + 1     AS doc_start,
            t.spec_start - 1    AS doc_end
        FROM t
        LEFT JOIN user_source x
            ON x.name       = t.package_name
            AND x.type      = 'PACKAGE'
            AND x.line      < t.spec_start
            AND REGEXP_LIKE(x.text, '^\s*$')
        GROUP BY t.package_name, t.module_name, t.module_type, t.overload, t.spec_start
    ) d
    LEFT JOIN user_source x
        ON x.name       = d.package_name
        AND x.type      = 'PACKAGE'
        AND x.line      BETWEEN d.doc_start AND d.doc_end
        AND NOT REGEXP_LIKE(x.text, '^\s*--\s*$')
    GROUP BY d.package_name, d.module_name, d.module_type, d.overload
) d
    ON d.package_name       = t.package_name
    AND d.module_name       = t.module_name
    AND d.module_type       = t.module_type
    AND NVL(d.overload, 1)  = NVL(t.overload, 1)
LEFT JOIN (
    SELECT t.package_name, t.module_name, t.module_type, t.overload, MAX(m.group_line) AS group_line
    FROM t
    LEFT JOIN (
        SELECT m.name, m.line AS group_line, MIN(x.line) - 1 AS group_end
        FROM (
            SELECT x.*
            FROM user_source x
            WHERE x.type = 'PACKAGE'
                AND REGEXP_LIKE(x.text, '^\s*--\s*###')
        ) m
        JOIN user_source x
            ON x.name       = m.name
            AND x.type      = m.type
            AND x.line      > m.line
            AND REGEXP_LIKE(x.text, '^\s*$')
        GROUP BY m.name, m.line
    ) m
        ON m.name           = t.package_name
        AND m.group_line    < t.spec_start
    GROUP BY t.package_name, t.module_name, t.module_type, t.overload
) m
    ON m.package_name       = t.package_name
    AND m.module_name       = t.module_name
    AND m.module_type       = t.module_type
    AND NVL(m.overload, 1)  = NVL(t.overload, 1)
LEFT JOIN user_source b
    ON b.name       = t.package_name
    AND b.type      = 'PACKAGE'
    AND b.line      BETWEEN t.spec_start AND t.spec_end
    AND REGEXP_LIKE(b.text, '^\s*(ACCESSIBLE BY)')
LEFT JOIN (
    SELECT gf.package_name, gf.module_name, gf.overload AS f_id, gp.overload AS p_id        ------------ if  module is here, then merge it to one line
    FROM g gf
    JOIN g gp
        ON gp.package_name  = gf.package_name
        AND gp.module_name  = gf.module_name
        AND gp.module_type  != gf.module_type
        --AND gp.module_type  = 'P'             -- start with F/P which have actual comment/desc
        AND gp.args         = gf.args
) g
    ON g.package_name   = t.package_name
    AND g.module_name   = t.module_name
    AND (
        (g.f_id = t.overload AND t.module_type = 'FUNCTION') OR
        (g.p_id = t.overload AND t.module_type = 'PROCEDURE')
    )
ORDER BY t.package_name, t.spec_start;
--
CREATE INDEX ix_logs_modules ON logs_modules (package_name, module_name, module_type, overload);
--
COMMENT ON MATERIALIZED VIEW logs_modules IS 'Find package modules (procedures and functions) and their boundaries (start-end lines)';
--
COMMENT ON COLUMN logs_modules.package_name    IS 'Package name';
COMMENT ON COLUMN logs_modules.module_name     IS 'Module name';
COMMENT ON COLUMN logs_modules.module_type     IS 'Module type';
COMMENT ON COLUMN logs_modules.overload        IS 'Overload ID';
COMMENT ON COLUMN logs_modules.spec_start      IS 'Module start in specification';
COMMENT ON COLUMN logs_modules.spec_end        IS 'Module end in specification';
COMMENT ON COLUMN logs_modules.spec_lines      IS 'Lines in specification';
COMMENT ON COLUMN logs_modules.body_start      IS 'Module start in body';
COMMENT ON COLUMN logs_modules.body_end        IS 'Module end in body';
COMMENT ON COLUMN logs_modules.body_lines      IS 'Lines in body';
COMMENT ON COLUMN logs_modules.private         IS 'Flag for private procedures';
COMMENT ON COLUMN logs_modules.args_in         IS 'Number of IN arguments';
COMMENT ON COLUMN logs_modules.args_out        IS 'Number of OUT arguments';
COMMENT ON COLUMN logs_modules.comment_        IS 'Description for package spec';
COMMENT ON COLUMN logs_modules.group_line      IS 'Group ID for blocks in Wiki';
COMMENT ON COLUMN logs_modules.f_id            IS 'Overload ID for F/P clone';



--
-- REFRESH MVIEW
--
BEGIN
    DBMS_SNAPSHOT.REFRESH('LOGS_MODULES');
END;
/
