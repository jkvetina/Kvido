CREATE OR REPLACE PACKAGE bug AS

    -- switch to enable or disable DBMS_OUTPUT
    output_enabled          BOOLEAN := TRUE;

    -- error log table name and max age fo records
    table_name              CONSTANT VARCHAR2(30)           := 'DEBUG_LOG';     -- used in purge_old
    table_rows_max_age      CONSTANT PLS_INTEGER            := 14;              -- max logs age in days

    -- flags
    flag_module             CONSTANT debug_log.flag%TYPE    := 'M';     -- Start of any module (procedure/function)
    flag_action             CONSTANT debug_log.flag%TYPE    := 'A';     -- Actions to distinguish different parts of code in longer modules
    flag_debug              CONSTANT debug_log.flag%TYPE    := 'D';     -- Debug
    flag_info               CONSTANT debug_log.flag%TYPE    := 'I';     -- Info (extended debug)
    flag_result             CONSTANT debug_log.flag%TYPE    := 'R';     -- Result of procedure for debugging purposes
    flag_warning            CONSTANT debug_log.flag%TYPE    := 'W';     -- Warning
    flag_error              CONSTANT debug_log.flag%TYPE    := 'E';     -- Error
    flag_query              CONSTANT debug_log.flag%TYPE    := 'Q';     -- Query with binded values appended via job/trigger
    flag_longops            CONSTANT debug_log.flag%TYPE    := 'L';     -- Longops row

    -- specify maximum length for trim
    length_action           CONSTANT PLS_INTEGER            := 48;      -- debug_log.action%TYPE
    length_arguments        CONSTANT PLS_INTEGER            := 2000;    -- debug_log.arguments%TYPE
    length_message          CONSTANT PLS_INTEGER            := 4000;    -- debug_log.message%TYPE

    -- append callstack for these flags; % for all
    track_callstack         CONSTANT VARCHAR2(30)       := flag_error || flag_warning || flag_module || flag_result;

    -- arguments separator
    splitter                CONSTANT CHAR := '|';

    -- action is mandatory, so we need default value
    empty_action            CONSTANT CHAR := '-';



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
        in_offset       PLS_INTEGER := NULL
    )
    RETURN debug_log.module_name%TYPE;



    --
    -- Return detailed info about caller
    --
    PROCEDURE get_caller_info (
        out_module_name     OUT debug_log.module_name%TYPE,
        out_module_line     OUT debug_log.module_line%TYPE,
        out_module_depth    OUT debug_log.module_depth%TYPE,
        out_parent_id       OUT debug_log.log_parent%TYPE
    );



    --
    -- Store log_id for current module
    --
    PROCEDURE set_caller_module (
        in_map_index    debug_log.module_name%TYPE,
        in_log_id       debug_log.log_id%TYPE
    );



    --
    -- Store log_id for current action
    --
    PROCEDURE set_caller_action (
        in_map_index    debug_log.module_name%TYPE,
        in_log_id       debug_log.log_id%TYPE
    );



    --
    -- Update DBMS_SESSION and DBMS_APPLICATION_INFO with current module and action
    --
    PROCEDURE set_session (
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
    -- Update progress for LONGOPS
    --
    PROCEDURE update_progress (
        in_progress         NUMBER := NULL  -- in percent (0-1)
    );



    --
    -- Update debug_log.message for requested log_id
    --
    PROCEDURE update_message (
        in_log_id           debug_log.log_id%TYPE,
        in_message          debug_log.message%TYPE
    );



    --
    -- Returns string to track down possible DML error; use in LOG ERROR INTO statements
    --
    FUNCTION get_dml_tracker
    RETURN VARCHAR2;



    --
    -- Purge old records from logs table
    --
    PROCEDURE purge_old;

END;
/

