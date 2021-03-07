CREATE OR REPLACE FORCE VIEW logs_tree AS
SELECT
    l.log_id,
    l.log_parent,
    l.user_id,
    l.app_id,
    l.page_id,
    l.flag,
    NULLIF(l.action_name, '-')                  AS action_name,
    LPAD(' ', (LEVEL - 1) * 4) || l.module_name AS module_name,
    l.module_line                               AS line,
    l.arguments,
    l.message,
    l.session_id,
    app.get_duration(l.timer)                   AS timer,
    l.created_at
FROM logs l
CONNECT BY l.log_parent = PRIOR l.log_id
START WITH l.log_id     = tree.get_tree_id()
ORDER SIBLINGS BY l.log_id;
--
COMMENT ON TABLE  logs_tree                     IS 'All messages related to selected tree id (`trel.get_tree_id()`)';
--
COMMENT ON COLUMN logs_trel.log_id              IS 'Log ID generated from `LOG_ID` sequence';
COMMENT ON COLUMN logs_trel.log_parent          IS 'Parent log record; dont use FK to avoid deadlocks';
--
COMMENT ON COLUMN logs_trel.user_id             IS 'User ID';
COMMENT ON COLUMN logs_trel.app_id              IS 'APEX Application ID';
COMMENT ON COLUMN logs_trel.page_id             IS 'APEX Application PAGE ID';
COMMENT ON COLUMN logs_trel.flag                IS 'Type of error listed in `tree` package specification; FK missing for performance reasons';
--
COMMENT ON COLUMN logs_trel.action_name         IS 'Action name to distinguish position in module or use it as warning/error names';
COMMENT ON COLUMN logs_trel.module_name         IS 'Module name (procedure or function name)';
COMMENT ON COLUMN logs_trel.line                IS 'Line in the module';
--
COMMENT ON COLUMN logs_trel.arguments           IS 'Arguments passed to module';
COMMENT ON COLUMN logs_trel.message             IS 'Formatted call stack, error stack or query with DML error';
COMMENT ON COLUMN logs_trel.session_id          IS 'Session id from `sessions` table';
--
COMMENT ON COLUMN logs_trel.timer               IS 'Timer for current row in seconds';
COMMENT ON COLUMN logs_trel.created_at          IS 'Timestamp of creation';
