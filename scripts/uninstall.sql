DROP TABLE logs         CASCADE CONSTRAINTS;
DROP TABLE logs_lobs    CASCADE CONSTRAINTS;
DROP TABLE logs_setup   CASCADE CONSTRAINTS;
DROP TABLE roles        CASCADE CONSTRAINTS;
DROP TABLE user_roles   CASCADE CONSTRAINTS;
DROP TABLE users        CASCADE CONSTRAINTS;
DROP TABLE sessions     CASCADE CONSTRAINTS;
--
PURGE RECYCLEBIN;

DROP SEQUENCE log_id;

DROP PACKAGE tree;
DROP PACKAGE sess;



/*
@../views/logs_tree.sql
@../views/logs_dml_errors.sql
@../views/logs_modules.sql
@../views/logs_profiler.sql
@../views/logs_profiler_sum.sql

@../procedures/process_dml_errors.sql

@../jobs/process_dml_errors_.sql
@../jobs/purge_old_logs.sql
*/

