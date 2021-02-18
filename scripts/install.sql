--
-- CREATE TABLES AND SEQUENCES
--
@../tables/logs.sql
@../tables/logs_lobs.sql
@../tables/apps.sql
@../tables/roles.sql
@../tables/users.sql
@../tables/user_roles.sql
@../tables/logs_setup.sql
@../tables/sessions.sql
@../tables/navigation.sql
@../tables/navigation_groups.sql
@../tables/navigation_extras.sql
@../tables/uploaders.sql
@../tables/uploaders_mapping.sql
@../tables/uploaded_files.sql
@../tables/uploaded_file_sheets.sql
@../tables/uploaded_file_cols.sql



--
-- CREATE PACKAGE SPECIFICATIONS
--
@../packages/tree.spec.sql
@../packages/sess.spec.sql
@../packages/apex.spec.sql
@../packages/auth.spec.sql
@../packages/app.spec.sql
@../packages/nav.spec.sql
@../packages/wiki.spec.sql



--
-- CREATE SEQUENCES
--
@../sequences/log_id.sql



--
-- CREATE PROCEDURES
--
@../procedures/recompile.sql
--
@../procedures/process_dml_errors.sql
@../procedures/sess_create_user.sql
@../procedures/sess_update_items.sql



--
-- PROFILER + COVERAGE TABLES
--
/*
@./proftab.sql
EXEC DBMS_PLSQL_CODE_COVERAGE.CREATE_COVERAGE_TABLES(force_it => TRUE);
*/



--
-- CREATE VIEWS
--
@../views/logs_tree.sql
@../views/logs_tree_extended.sql
@../views/logs_dml_errors.sql
--
-- @TODO: TOO SLOW
@../views/logs_modules.sql
--
--@../views/logs_profiler.sql
--@../views/logs_profiler_sum.sql
--
@../views/apex_app_items.sql
@../views/apex_page_items.sql
--
@../views/nav_top.sql
--
@../views/p900_dashboard.sql
@../views/p901_logs.sql
@../views/p902_sessions.sql
--
@../views/p910_nav_pages_to_add.sql
@../views/p910_nav_pages_to_remove.sql
@../views/p910_nav_overview.sql
@../views/p910_nav_groups.sql
@../views/p910_auth_schemes.sql
@../views/p910_nav_left.sql
@../views/p910_nav_right.sql



--
-- CREATE TRIGGERS
--
@../triggers/apps__.sql
@../triggers/events__.sql
@../triggers/languages__.sql
--@../triggers/logs__.sql
--@../triggers/logs_events__.sql
--@../triggers/logs_lobs__.sql
--@../triggers/logs_modules__.sql
@../triggers/logs_setup__.sql
@../triggers/navigation__.sql
@../triggers/navigation_extras__.sql
@../triggers/navigation_groups__.sql
@../triggers/roles__.sql
--@../triggers/sessions__.sql
@../triggers/uploaded_file_cols__.sql
@../triggers/uploaded_file_sheets__.sql
@../triggers/uploaded_files__.sql
@../triggers/uploaders__.sql
@../triggers/uploaders_mapping__.sql
@../triggers/user_roles__.sql
@../triggers/users__.sql



--
-- CREATE PACKAGES
--
EXEC recompile;
--
@../packages/tree.sql
@../packages/sess.sql
@../packages/apex.sql
@../packages/wiki.sql
@../packages/nav.sql
@../packages/app.sql
@../packages/auth.sql



--
-- CREATE JOBS
--
@../jobs/process_dml_errors_.sql
@../jobs/purge_old_logs.sql



--
-- REFRESH VIEW
--
EXEC recompile;
--
BEGIN
    DBMS_SNAPSHOT.REFRESH('LOGS_MODULES');
END;
/

