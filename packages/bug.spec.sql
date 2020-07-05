CREATE OR REPLACE PACKAGE bug AS

    -- switch to enable or disable DBMS_OUTPUT
    output_enabled          BOOLEAN := TRUE;

    -- error log table name and max age fo records
    table_name              CONSTANT VARCHAR2(30)           := 'DEBUG_LOG';     -- used in purge_old
    table_rows_max_age      CONSTANT PLS_INTEGER            := 14;              -- max logs age in days

    -- view which holds all DML errors
    view_dml_errors         CONSTANT VARCHAR2(30)           := 'DEBUG_LOG_DML_ERRORS';

    -- flags
    flag_module             CONSTANT debug_log.flag%TYPE    := 'M';     -- start of any module (procedure/function)
    flag_action             CONSTANT debug_log.flag%TYPE    := 'A';     -- actions to distinguish different parts of code in longer modules
    flag_debug              CONSTANT debug_log.flag%TYPE    := 'D';     -- debug
    flag_info               CONSTANT debug_log.flag%TYPE    := 'I';     -- info (extended debug)
    flag_result             CONSTANT debug_log.flag%TYPE    := 'R';     -- result of procedure for debugging purposes
    flag_warning            CONSTANT debug_log.flag%TYPE    := 'W';     -- warning
    flag_error              CONSTANT debug_log.flag%TYPE    := 'E';     -- error
    flag_longops            CONSTANT debug_log.flag%TYPE    := 'L';     -- longops row
    flag_scheduler          CONSTANT debug_log.flag%TYPE    := 'S';     -- scheduler run planned
    flag_context            CONSTANT debug_log.flag%TYPE    := 'X';     -- CTX package calls (so you can ignore them)
    flag_profiler           CONSTANT debug_log.flag%TYPE    := 'P';     -- profiler initiated

    -- specify maximum length for trim
    length_action           CONSTANT PLS_INTEGER            := 48;      -- debug_log.action%TYPE
    length_arguments        CONSTANT PLS_INTEGER            := 1000;    -- debug_log.arguments%TYPE
    length_message          CONSTANT PLS_INTEGER            := 4000;    -- debug_log.message%TYPE
    length_contexts         CONSTANT PLS_INTEGER            := 1000;    -- debug_log.contexts%TYPE

    -- append callstack for these flags; % for all
    track_callstack         CONSTANT VARCHAR2(30)           := flag_error || flag_warning || flag_module || flag_result || flag_context;
    track_contexts          CONSTANT VARCHAR2(30)           := flag_error || flag_warning || flag_module || flag_result || flag_context;

    -- arguments separator
    splitter                CONSTANT CHAR                   := '|';

    -- splitters for payload
    splitter_values         CONSTANT CHAR                   := '=';
    splitter_rows           CONSTANT CHAR                   := '|';
    splitter_package        CONSTANT CHAR                   := '.';

    -- action is mandatory, so we need default value
    empty_action            CONSTANT CHAR                   := '-';

    -- code for app exception
    app_exception_code      CONSTANT PLS_INTEGER            := -20000;
    app_exception           EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT(app_exception, app_exception_code);

    -- owner of DML error tables
    dml_tables_owner        CONSTANT VARCHAR2(30)           := USER;
    dml_tables_postfix      CONSTANT VARCHAR2(30)           := '_E$';



    --
    -- Returns clean call stack
    --
    FUNCTION get_call_stack
    RETURN debug_log.message%TYPE;



    --
    -- Returns error stack
    --
    FUNCTION get_error_stack
    RETURN debug_log.message%TYPE;



    --
    -- Returns last log_id for E flag
    --
    FUNCTION get_error_id
    RETURN debug_log.log_id%TYPE;



    --
    -- Returns last log_id for any flag
    --
    FUNCTION get_log_id
    RETURN debug_log.log_id%TYPE;



    --
    -- Returns root log_id for passed log_id
    --
    FUNCTION get_root_id (
        in_log_id       debug_log.log_id%TYPE := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Returns log_id for LOGS_TREE view
    --
    FUNCTION get_tree_id
    RETURN debug_log.log_id%TYPE;



    --
    -- Set log_id which will be viewed by LOGS_TREE view
    --
    PROCEDURE set_tree_id (
        in_log_id       debug_log.log_id%TYPE
    );



    --
    -- Returns arguments merged into one string
    --
    FUNCTION get_arguments (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.arguments%TYPE;



    --
    -- Returns procedure name which called this function with possible offset
    --
    FUNCTION get_caller_name (
        in_offset           debug_log.module_depth%TYPE     := 0,
        in_skip_this        BOOLEAN                         := TRUE,
        in_attach_line      BOOLEAN                         := FALSE
    )
    RETURN debug_log.module_name%TYPE;



    --
    -- Return detailed info about caller
    --
    PROCEDURE get_caller (
        out_module_name     OUT debug_log.module_name%TYPE,
        out_module_line     OUT debug_log.module_line%TYPE,
        out_module_depth    OUT debug_log.module_depth%TYPE,
        out_parent_id       OUT debug_log.log_parent%TYPE
    );



    --
    -- Store log_id for current module
    --
    PROCEDURE update_map (
        in_map_index    debug_log.module_name%TYPE,
        in_log_id       debug_log.log_id%TYPE
    );



    --
    -- Update DBMS_SESSION and DBMS_APPLICATION_INFO with current module and action
    --
    PROCEDURE update_session (
        in_user_id          debug_log.user_id%TYPE,
        in_module_name      debug_log.module_name%TYPE,
        in_action_name      debug_log.action_name%TYPE
    );



    --
    -- Main function called at the very start of every application module (procedure, function)
    --
    FUNCTION log_module (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_module function
    --
    PROCEDURE log_module (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    -- Overloaded variant used in schedulers to link calls to proper tree branch
    --
    PROCEDURE log_module (
        in_scheduler_id     debug_log.log_id%TYPE
    );



    --
    -- Main function to distinguish chosen path in longer modules; make sure to call log_module first
    --
    FUNCTION log_action (
        in_action       debug_log.action_name%TYPE,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_action function
    --
    PROCEDURE log_action (
        in_action       debug_log.action_name%TYPE,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    --
    --
    FUNCTION log_debug (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_debug function
    --
    PROCEDURE log_debug (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    --
    --
    FUNCTION log_result (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_result function
    --
    PROCEDURE log_result (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    --
    --
    FUNCTION log_warning (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_warning function
    --
    PROCEDURE log_warning (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    --
    --
    FUNCTION log_error (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_error function
    --
    PROCEDURE log_error (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    -- Log error and RAISE exception action_name|log_id
    --
    PROCEDURE raise_error (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    );



    --
    -- Log requested SYS_CONTEXT values
    --
    FUNCTION log_context (
        in_namespace        debug_log.arguments%TYPE    := '%',
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_context function
    --
    PROCEDURE log_context (
        in_namespace        debug_log.arguments%TYPE    := '%',
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Log session NLS parameters
    --
    FUNCTION log_nls (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_nls function
    --
    PROCEDURE log_nls (
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Log USERENV values
    --
    FUNCTION log_userenv (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_userenv function
    --
    PROCEDURE log_userenv (
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Log CGI_ENV values (when called from web)
    --
    FUNCTION log_cgi (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_cgi function
    --
    PROCEDURE log_cgi (
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Get APEX items for selected/current page
    --
    FUNCTION log_apex_items (
        in_page_id          debug_log.page_id%TYPE      := NULL,
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_apex_items function
    --
    PROCEDURE log_apex_items (
        in_page_id          debug_log.page_id%TYPE      := NULL,
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Get APEX global items
    --
    FUNCTION log_apex_globals (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Same as log_apex_globals function
    --
    PROCEDURE log_apex_globals (
        in_filter           debug_log.arguments%TYPE    := '%'
    );



    --
    -- Log scheduler call and return log_id so the scheduler log can be linked to this log_id
    --
    FUNCTION log_scheduler (
        in_action       debug_log.action_name%TYPE  := NULL,
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    )
    RETURN debug_log.log_id%TYPE;



    --
    -- Update progress for LONGOPS
    --
    PROCEDURE log_progress (
        in_progress         NUMBER := NULL  -- in percent (0-1)
    );



    --
    -- Internal function which creates records in logs table; returns assigned log_id
    --
    FUNCTION log__ (
        in_action_name      debug_log.action_name%TYPE,
        in_flag             debug_log.flag%TYPE,
        in_arguments        debug_log.arguments%TYPE    := NULL,
        in_message          debug_log.message%TYPE      := NULL,
        in_parent_id        debug_log.log_parent%TYPE   := NULL
    )
    RETURN debug_log.log_id%TYPE
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    );



    --
    -- Same as log__ function
    --
    PROCEDURE log__ (
        in_action_name      debug_log.action_name%TYPE,
        in_flag             debug_log.flag%TYPE,
        in_arguments        debug_log.arguments%TYPE    := NULL,
        in_message          debug_log.message%TYPE      := NULL,
        in_parent_id        debug_log.log_parent%TYPE   := NULL
    )
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    );



    --
    -- Attach CLOB to existing/recent logs record
    --
    PROCEDURE attach_clob (
        in_payload          CLOB,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    );



    --
    -- Attach XML to existing/recent logs record
    --
    PROCEDURE attach_clob (
        in_payload          XMLTYPE,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    );



    --
    -- Attach BLOB to existing/recent logs record
    --
    PROCEDURE attach_blob (
        in_payload          BLOB,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    );



    --
    -- Update debug_log.timer for current module (or requested log_id)
    --
    PROCEDURE update_timer (
        in_log_id           debug_log.log_id%TYPE := NULL
    );



    --
    -- Converts record from DML ERR table to MERGE query
    --
    FUNCTION get_dml_query (
        in_log_id           debug_log.log_id%TYPE,
        in_table_name       debug_log.module_name%TYPE,
        in_table_rowid      VARCHAR2,
        in_action           CHAR  -- [I|U|D]
    )
    RETURN debug_log_lobs.payload_clob%TYPE;



    --
    -- Link errors stored in requested DML ERR table to parent log_id
    --
    PROCEDURE process_dml_error (
        in_log_id           debug_log.log_id%TYPE,
        in_error_table      VARCHAR2,   -- remove references to debug_log_dml_errors view
        in_table_name       VARCHAR2,   -- because it can get invalidated too often
        in_table_rowid      VARCHAR2,
        in_action           VARCHAR2
    );



    --
    -- Drop DML ERR tables matching in_table_like filter
    --
    PROCEDURE drop_dml_tables (
        in_table_like       debug_log.module_name%TYPE
    );



    --
    -- Recreate DML ERR tables matching in_table_like filter
    --
    PROCEDURE create_dml_tables (
        in_table_like       debug_log.module_name%TYPE
    );



    --
    -- Merge all DML ERR tables into single view
    --
    PROCEDURE create_dml_errors_view;



    --
    -- Purge old records from logs table
    --
    PROCEDURE purge_old;

END;
/

