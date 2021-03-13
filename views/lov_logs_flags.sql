CREATE OR REPLACE FORCE VIEW lov_logs_flags AS
SELECT 'M' AS flag, 'Module called' AS description_     FROM DUAL UNION ALL
SELECT 'A' AS flag, 'Action in module'                  FROM DUAL UNION ALL
SELECT 'D' AS flag, 'Debug for developers'              FROM DUAL UNION ALL
SELECT 'I' AS flag, 'Info (details)'                    FROM DUAL UNION ALL
SELECT 'R' AS flag, 'Result of module'                  FROM DUAL UNION ALL
SELECT 'W' AS flag, 'Warning'                           FROM DUAL UNION ALL
SELECT 'E' AS flag, 'Error'                             FROM DUAL UNION ALL
SELECT 'L' AS flag, 'Longops'                           FROM DUAL UNION ALL
SELECT 'S' AS flag, 'Scheduler planned'                 FROM DUAL UNION ALL
SELECT 'P' AS flag, 'APEX page visited/requested'       FROM DUAL UNION ALL
SELECT 'F' AS flag, 'APEX form submitted'               FROM DUAL UNION ALL
SELECT 'G' AS flag, 'Trigger called'                    FROM DUAL UNION ALL
SELECT 'B' AS flag, 'Business event'                    FROM DUAL;
--
COMMENT ON TABLE lov_logs_flags IS 'LOV with flags used in `TREE` package spec';

