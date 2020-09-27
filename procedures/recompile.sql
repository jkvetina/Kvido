CREATE OR REPLACE PROCEDURE recompile (
    in_filter_type      VARCHAR2    := '%',
    in_filter_name      VARCHAR2    := '%',
    in_code_type        VARCHAR2    := 'INTERPRETED',
    in_scope            VARCHAR2    := 'IDENTIFIERS:ALL, STATEMENTS:ALL',
    in_warnings         VARCHAR2    := 'ENABLE:SEVERE, ENABLE:PERFORMANCE',
    in_optimize         NUMBER      := 2,
    in_ccflags          VARCHAR2    := NULL,
    in_invalid_only     BOOLEAN     := TRUE
) AS
    in_invalids         CONSTANT CHAR       := CASE WHEN in_invalid_only THEN 'Y' END;
    ccflags             VARCHAR2(32767);
    query_              VARCHAR2(32767);
    invalids            PLS_INTEGER;
BEGIN
    /**
     * This procedure is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     */

    -- first recompile invalid and requested objects
    DBMS_OUTPUT.PUT_LINE('--');
    DBMS_OUTPUT.PUT('INVALID: ');
    --
    FOR c IN (
        SELECT o.object_name, o.object_type
        FROM user_objects o
        WHERE o.status          != 'VALID'
            AND o.object_type   NOT IN ('SEQUENCE', 'MATERIALIZED VIEW')
            AND o.object_name   != $$PLSQL_UNIT         -- not this procedure
        UNION ALL
        SELECT o.object_name, o.object_type
        FROM user_objects o
        WHERE in_invalids       IS NULL
            AND o.object_type   IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER', 'VIEW', 'SYNONYM')
            AND (o.object_type  LIKE in_filter_type OR in_filter_type IS NULL)
            AND (o.object_name  LIKE in_filter_name OR in_filter_name IS NULL)
            AND o.object_name   != $$PLSQL_UNIT         -- not this procedure
    ) LOOP
        -- apply ccflags only relevant to current object
        IF in_ccflags IS NOT NULL THEN
            BEGIN
                SELECT
                    LISTAGG(REGEXP_SUBSTR(in_ccflags, '(' || s.flag_name || ':[^,]+)', 1, 1, NULL, 1), ', ')
                        WITHIN GROUP (ORDER BY s.flag_name)
                INTO ccflags
                FROM (
                    SELECT DISTINCT REGEXP_SUBSTR(s.text, '[$].*\s[$][$]([A-Z0-9-_]+)\s.*[$]', 1, 1, NULL, 1) AS flag_name
                    FROM user_source s
                    WHERE REGEXP_LIKE(s.text, '[$].*\s[$][$][A-Z0-9-_]+\s.*[$]')
                        AND s.name = c.object_name
                        AND s.type = c.object_type
                ) s;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ccflags := NULL;
            END;
        END IF;
        --
        BEGIN
            query_ := 'ALTER ' || REPLACE(c.object_type, ' BODY', '') || ' ' || c.object_name || ' COMPILE' ||
                CASE WHEN c.object_type LIKE '% BODY' THEN ' BODY' END || ' ' ||
                CASE WHEN c.object_type IN (
                    'PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER'
                ) THEN
                    CASE WHEN ccflags       IS NOT NULL THEN 'PLSQL_CCFLAGS = '''       || RTRIM(ccflags) || ''' ' END ||
                    CASE WHEN in_code_type  IS NOT NULL THEN 'PLSQL_CODE_TYPE = '       || in_code_type || ' ' END ||
                    CASE WHEN in_optimize   IS NOT NULL THEN 'PLSQL_OPTIMIZE_LEVEL = '  || in_optimize || ' ' END ||
                    CASE WHEN in_warnings   IS NOT NULL THEN 'PLSQL_WARNINGS = '''      || REPLACE(in_warnings, ',', ''', ''') || ''' ' END ||
                    CASE WHEN in_scope      IS NOT NULL THEN 'PLSCOPE_SETTINGS = '''    || RTRIM(in_scope) || ''' ' END ||
                    'REUSE SETTINGS'
                END;
            --
            EXECUTE IMMEDIATE query_;
            --DBMS_OUTPUT.PUT_LINE(query_);
            DBMS_OUTPUT.PUT('.');
        EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT('!');  -- something went wrong
        END;
    END LOOP;

    -- show number of invalid objects
    SELECT COUNT(*) INTO invalids
    FROM user_objects o
    WHERE o.status          != 'VALID'
        AND o.object_type   != 'MATERIALIZED VIEW'
        AND o.object_name   != $$PLSQL_UNIT;        -- not this procedure
    --
    DBMS_OUTPUT.PUT_LINE(' -> ' || invalids);
    DBMS_OUTPUT.PUT_LINE('');

    -- list invalid objects
    IF invalids > 0 THEN
        FOR c IN (
            SELECT object_type, LISTAGG(object_name, ', ') WITHIN GROUP (ORDER BY object_name) AS objects
            FROM (
                SELECT DISTINCT o.object_type, o.object_name
                FROM user_objects o
                WHERE o.status      != 'VALID'
                AND o.object_type   != 'MATERIALIZED VIEW'
                ORDER BY o.object_type, o.object_name
            )
            GROUP BY object_type
            ORDER BY object_type
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || RPAD(c.object_type || ':', 15, ' ') || ' ' || c.objects);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END IF;
END;
/

