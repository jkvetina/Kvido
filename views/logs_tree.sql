CREATE OR REPLACE FORCE VIEW logs_tree AS
SELECT
    e.log_id,
    e.log_parent,
    e.user_id,
    e.app_id,
    e.page_id,
    e.flag,
    NULLIF(e.action_name, '-')                  AS action_name,
    LPAD(' ', (LEVEL - 1) * 4) || e.module_name AS module_name,
    e.module_line                               AS line,
    e.arguments,
    e.message,
    e.session_id,
    e.timer,
    e.created_at
FROM logs e
CONNECT BY e.log_parent = PRIOR e.log_id
START WITH e.log_id     = tree.get_tree_id()
ORDER SIBLINGS BY e.log_id;
--
COMMENT ON TABLE  logs_tree                     IS 'All messages related to selected tree id (`tree.get_tree_id()`)';
--
COMMENT ON COLUMN logs_tree.log_id              IS 'Log ID generated from `LOG_ID` sequence';
COMMENT ON COLUMN logs_tree.log_parent          IS 'Parent log record; dont use FK to avoid deadlocks';
--
COMMENT ON COLUMN logs_tree.user_id             IS 'User ID';
COMMENT ON COLUMN logs_tree.app_id              IS 'APEX Application ID';
COMMENT ON COLUMN logs_tree.page_id             IS 'APEX Application PAGE ID';
COMMENT ON COLUMN logs_tree.flag                IS 'Type of error listed in `tree` package specification; FK missing for performance reasons';
--
COMMENT ON COLUMN logs_tree.action_name         IS 'Action name to distinguish position in module or use it as warning/error names';
COMMENT ON COLUMN logs_tree.module_name         IS 'Module name (procedure or function name)';
COMMENT ON COLUMN logs_tree.line                IS 'Line in the module';
--
COMMENT ON COLUMN logs_tree.arguments           IS 'Arguments passed to module';
COMMENT ON COLUMN logs_tree.message             IS 'Formatted call stack, error stack or query with DML error';
COMMENT ON COLUMN logs_tree.session_id          IS 'Session id from `sessions` table';
--
COMMENT ON COLUMN logs_tree.timer               IS 'Timer for current row in seconds';
COMMENT ON COLUMN logs_tree.created_at          IS 'Timestamp of creation';
