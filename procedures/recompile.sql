CREATE OR REPLACE PROCEDURE recompile (
    in_filter_type      VARCHAR2    := '%',
    in_filter_name      VARCHAR2    := '%',
    in_code_type        VARCHAR2    := 'INTERPRETED',
    in_scope            VARCHAR2    := 'IDENTIFIERS:ALL, STATEMENTS:ALL',
    in_warnings         VARCHAR2    := 'ENABLE:SEVERE, ENABLE:PERFORMANCE',
    in_optimize         NUMBER      := 3,
    in_ccflags          VARCHAR2    := NULL,
    in_invalid_only     CHAR        := 'Y'
) AS
BEGIN
    /**
     * This procedure is part of the BUG project under MIT licence.
     * https://github.com/jkvetina/BUG/
     *
     * Copyright (c) Jan Kvetina, 2020
     */

    -- first recompile invalid and requested objects
    DBMS_OUTPUT.PUT_LINE('--');
    DBMS_OUTPUT.PUT('INVALID: ');
    --
    FOR c IN (
        SELECT o.object_name, o.object_type, '' AS ccflags
        FROM user_objects o
        WHERE o.status          != 'VALID'
            AND o.object_type   NOT IN ('SEQUENCE', 'MATERIALIZED VIEW')
            AND o.object_name   != $$PLSQL_UNIT         -- not this procedure
        UNION ALL
        SELECT o.object_name, o.object_type, '' AS ccflags
        FROM user_objects o
        WHERE in_invalid_only   != 'Y'
            AND o.object_type   IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER', 'VIEW', 'SYNONYM')
            AND o.object_type   LIKE in_filter_type
            AND o.object_name   != $$PLSQL_UNIT         -- not this procedure
            AND o.object_name   LIKE in_filter_name
    ) LOOP
        -- apply ccflags only relevant to current object
        BEGIN
            SELECT
                LISTAGG(REGEXP_SUBSTR(in_ccflags, '(' || s.flag_name || ':[^,]+)', 1, 1, NULL, 1), ', ')
                    WITHIN GROUP (ORDER BY s.flag_name)
            INTO c.ccflags
            FROM (
                SELECT MAX(REGEXP_SUBSTR(s.text, '[$].*\s[$][$]([A-Z0-9-_]+)\s.*[$]', 1, 1, NULL, 1)) AS flag_name
                FROM user_source s
                WHERE REGEXP_LIKE(s.text, '[$].*\s[$][$][A-Z0-9-_]+\s.*[$]')
                    AND s.name = c.object_name
                    AND s.type = c.object_type
                HAVING MAX(REGEXP_SUBSTR(s.text, '[$].*\s[$][$]([A-Z0-9-_]+)\s.*[$]', 1, 1, NULL, 1)) IS NOT NULL
            ) s;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            c.ccflags := '';
        END;
        --
        BEGIN
            EXECUTE IMMEDIATE
                'ALTER ' || REPLACE(c.object_type, ' BODY', '') || ' ' ||
                c.object_name || ' COMPILE' ||
                CASE WHEN c.object_type LIKE '% BODY' THEN ' BODY' END || ' ' ||
                CASE WHEN c.object_type IN (
                    'PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER'
                ) THEN
                    'PLSQL_CCFLAGS = '''        || RTRIM(c.ccflags) || ''' ' ||
                    'PLSQL_CODE_TYPE = '        || in_code_type || ' ' ||
                    'PLSQL_OPTIMIZE_LEVEL = '   || in_optimize || ' ' ||
                    'PLSQL_WARNINGS = '''       || REPLACE(in_warnings, ',', ''', ''') || ''' ' ||
                    'PLSCOPE_SETTINGS = '''     || in_scope || ''' ' ||
                    'REUSE SETTINGS'            -- store in user_plsql_object_settings
                END;
            DBMS_OUTPUT.PUT('.');
        EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT('!');  -- something went wrong
        END;
    END LOOP;

    -- show number of invalid objects
    FOR c IN (
        SELECT COUNT(*) AS count_
        FROM user_objects o
        WHERE o.status          != 'VALID'
            AND o.object_type   NOT IN ('SEQUENCE', 'MATERIALIZED VIEW')
            AND o.object_name   != $$PLSQL_UNIT         -- not this procedure
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(' -> ' || c.count_);
    END LOOP;

    -- list invalid objects
    DBMS_OUTPUT.PUT_LINE('');
    FOR c IN (
        SELECT object_type, LISTAGG(object_name, ', ') WITHIN GROUP (ORDER BY object_name) AS objects
        FROM (
            SELECT DISTINCT o.object_type, o.object_name
            FROM user_objects o
            WHERE o.status          != 'VALID'
                AND o.object_type   NOT IN ('SEQUENCE', 'MATERIALIZED VIEW')
            ORDER BY o.object_type, o.object_name
        )
        GROUP BY object_type
        ORDER BY object_type
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || RPAD(c.object_type || ':', 15, ' ') || ' ' || c.objects);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
END;
/

