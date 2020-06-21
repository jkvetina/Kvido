CREATE OR REPLACE PACKAGE err AS

    -- switch to enable or disable DBMS_OUTPUT
    output_enabled          BOOLEAN := TRUE;

    -- error log table name and max age fo records
    table_name              CONSTANT VARCHAR2(30)       := 'LOGS';  -- used in purge_old
    table_rows_max_age      CONSTANT PLS_INTEGER        := 14;      -- max logs age in days

    -- flags
    flag_module             CONSTANT logs.flag%TYPE     := 'M';     -- Start of any module (procedure/function)
    flag_action             CONSTANT logs.flag%TYPE     := 'A';     -- Action requested by user (button or link of FE)
    flag_error              CONSTANT logs.flag%TYPE     := 'E';     -- Error
    flag_warning            CONSTANT logs.flag%TYPE     := 'W';     -- Warning
    flag_debug              CONSTANT logs.flag%TYPE     := 'D';     -- Debug
    flag_result             CONSTANT logs.flag%TYPE     := 'R';     -- Result of procedure for log_debugging purposes
    flag_query              CONSTANT logs.flag%TYPE     := 'Q';     -- Query with binded values appended via job/trigger

    -- specify maximum length for trim
    length_action           CONSTANT PLS_INTEGER        := 48;      -- logs.action%TYPE
    length_arguments        CONSTANT PLS_INTEGER        := 2000;    -- logs.arguments%TYPE
    length_message          CONSTANT PLS_INTEGER        := 4000;    -- logs.message%TYPE

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
    RETURN logs.message%TYPE;



    --
    -- Returns error stack
    --
    FUNCTION get_error_stack
    RETURN logs.message%TYPE;



    --
    -- Returns last log_id for E flag
    --
    FUNCTION get_error_id
    RETURN logs.log_id%TYPE;



    --
    -- Returns last log_id for any flag
    --
    FUNCTION get_log_id
    RETURN logs.log_id%TYPE;



    --
    -- Returns root log_id for passed log_id
    --
    FUNCTION get_root_id (
        in_log_id       logs.log_id%TYPE := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Returns arguments merged into one string
    --
    FUNCTION get_arguments (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.arguments%TYPE;



    --
    -- Returns procedure name which called this function with possible offset
    --
    FUNCTION get_caller_name (
        in_offset       PLS_INTEGER := NULL
    )
    RETURN logs.module_name%TYPE;



    --
    -- Return detailed info about caller
    --
    PROCEDURE get_caller_info (
        out_module_name     OUT logs.module_name%TYPE,
        out_module_line     OUT logs.module_line%TYPE,
        out_module_depth    OUT logs.module_depth%TYPE,
        out_parent_id       OUT logs.log_parent%TYPE
    );



    --
    -- Store log_id for current module
    --
    PROCEDURE set_caller_module (
        in_map_index    logs.module_name%TYPE,
        in_log_id       logs.log_id%TYPE
    );



    --
    -- Store log_id for current action
    --
    PROCEDURE set_caller_action (
        in_map_index    logs.module_name%TYPE,
        in_log_id       logs.log_id%TYPE
    );



    --
    -- Main function called at the very start of every application module (procedure, function)
    --
    FUNCTION log_module (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_module function
    --
    PROCEDURE log_module (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Main function to distinguish chosen path in longer modules; make sure to call log_module first
    --
    FUNCTION log_action (
        in_action       logs.action_name%TYPE,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_action function
    --
    PROCEDURE log_action (
        in_action       logs.action_name%TYPE,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    --
    --
    FUNCTION log_debug (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_debug function
    --
    PROCEDURE log_debug (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    --
    --
    FUNCTION log_result (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_result function
    --
    PROCEDURE log_result (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    --
    --
    FUNCTION log_warning (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_warning function
    --
    PROCEDURE log_warning (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    --
    --
    FUNCTION log_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Same as log_error function
    --
    PROCEDURE log_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Log error and RAISE exception action_name|log_id
    --
    PROCEDURE raise_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Internal function which creates records in logs table; returns assigned log_id
    --
    FUNCTION log__ (
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE,
        in_arguments        logs.arguments%TYPE     := NULL,
        in_message          logs.message%TYPE       := NULL,
        in_parent_id        logs.log_parent%TYPE    := NULL
    )
    RETURN logs.log_id%TYPE
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    );



    --
    -- Same as log__ function
    --
    PROCEDURE log__ (
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE,
        in_arguments        logs.arguments%TYPE     := NULL,
        in_message          logs.message%TYPE       := NULL,
        in_parent_id        logs.log_parent%TYPE    := NULL
    )
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    );



    --
    -- Update DBMS_SESSION and DBMS_APPLICATION_INFO with current module and action
    --
    PROCEDURE set_session (
        in_user_id          logs.user_id%TYPE,
        in_module_name      logs.module_name%TYPE,
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE
    );



    --
    -- Update logs.timer for current module (or requested log_id)
    --
    PROCEDURE update_timer (
        in_log_id           logs.log_id%TYPE := NULL
    );



    --
    -- Update logs.message for requested log_id
    --
    PROCEDURE update_message (
        in_log_id           logs.log_id%TYPE,
        in_message          logs.message%TYPE
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

