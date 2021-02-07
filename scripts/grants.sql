GRANT CONNECT, ALTER SESSION            TO dev;
GRANT CREATE TABLE                      TO dev;
GRANT CREATE VIEW                       TO dev;
GRANT CREATE PROCEDURE                  TO dev;
GRANT CREATE SEQUENCE                   TO dev;
GRANT CREATE MATERIALIZED VIEW          TO dev;
GRANT CREATE SYNONYM                    TO dev;
GRANT CREATE TRIGGER                    TO dev;
GRANT CREATE TYPE                       TO dev;
--
GRANT EXECUTE ON DBMS_SESSION           TO dev;
GRANT EXECUTE ON DBMS_SCHEDULER         TO dev;
GRANT EXECUTE ON DBMS_PROFILER          TO dev;
GRANT EXECUTE ON DBMS_HPROF             TO dev;
--
GRANT SELECT ON v$sql                   TO dev;
GRANT SELECT ON v$sql_cursor            TO dev;
GRANT SELECT ON v$session               TO dev;
GRANT SELECT ON v$session_longops       TO dev;

