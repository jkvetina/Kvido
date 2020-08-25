CREATE OR REPLACE PACKAGE BODY bug AS

    recent_log_id           debug_log.log_id%TYPE;    -- last log_id in session (any flag)
    recent_error_id         debug_log.log_id%TYPE;    -- last real log_id in session (with E flag)
    recent_tree_id          debug_log.log_id%TYPE;    -- selected log_id for DEBUG_LOG_TREE view

    -- array to hold recent log_id; array[depth + module] = log_id
    TYPE arr_map_module_to_id IS
        TABLE OF debug_log.log_id%TYPE
        INDEX BY debug_log.module_name%TYPE;
    --
    map_modules             arr_map_module_to_id;
    map_actions             arr_map_module_to_id;

    -- module_name LIKE to switch flag_module to flag_context
    trigger_ctx             CONSTANT debug_log.module_name%TYPE     := 'CTX.%';

    internal_log_fn         CONSTANT debug_log.module_name%TYPE     := 'BUG.LOG__';

    -- arrays to specify adhoc requests
    TYPE arr_log_setup      IS VARRAY(20) OF debug_log_setup%ROWTYPE;
    --
    rows_whitelist          arr_log_setup := arr_log_setup();
    rows_blacklist          arr_log_setup := arr_log_setup();
    rows_profiler           arr_log_setup := arr_log_setup();
    --
    rows_limit              CONSTANT PLS_INTEGER := 100;  -- match arr_log_setup VARRAY

    -- log_id where profiler started
    curr_profiler_id        PLS_INTEGER;
    curr_coverage_id        PLS_INTEGER;
    --
    parent_profiler_id      PLS_INTEGER;
    parent_coverage_id      PLS_INTEGER;

    -- possible exception when parsing call stack
    BAD_DEPTH EXCEPTION;
    PRAGMA EXCEPTION_INIT(BAD_DEPTH, -64610);



    FUNCTION get_call_stack
    RETURN debug_log.message%TYPE
    AS
        out_stack       VARCHAR2(32767);
        out_module      debug_log.module_name%TYPE;
    BEGIN
        -- better version of DBMS_UTILITY.FORMAT_CALL_STACK
        FOR i IN REVERSE 2 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP  -- 2 = ignore this function
            out_module := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            CONTINUE WHEN
                (out_module = internal_log_fn AND i <= 2)   -- skip target function
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL;     -- skip DML queries
            --
            out_stack := out_stack || out_module || ' [' || UTL_CALL_STACK.UNIT_LINE(i) || ']' || CHR(10);
        END LOOP;

        -- cleanup useless info
        out_stack := REGEXP_REPLACE(out_stack, '\s+DBMS_SQL.EXECUTE [[]\d+[]]\s+> BLOCK [[]\d+[]]', '');
        out_stack := REGEXP_REPLACE(out_stack, '\s+DBMS_SYS_SQL.EXECUTE(.*)', '');
        out_stack := REGEXP_REPLACE(out_stack, '\s+UT(\.|_[A-Z0-9_]*\.)[A-Z0-9_]+ [[]\d+[]]', '');   -- ut/plsql
        --
        RETURN SUBSTR(out_stack, 1, bug.length_message);
    END;



    FUNCTION get_error_stack
    RETURN debug_log.message%TYPE
    AS
        out_stack VARCHAR2(32767);
    BEGIN
        -- switch NLS to get error message in english
        DBMS_SESSION.SET_NLS('NLS_LANGUAGE', '''ENGLISH''');

        -- better version of DBMS_UTILITY.FORMAT_ERROR_STACK, FORMAT_ERROR_BACKTRACE
        FOR i IN REVERSE 1 .. UTL_CALL_STACK.ERROR_DEPTH LOOP
            BEGIN
                out_stack := out_stack ||
                    UTL_CALL_STACK.BACKTRACE_UNIT(i) || ' [' || UTL_CALL_STACK.BACKTRACE_LINE(i) || '] ' ||
                    'ORA-' || LPAD(UTL_CALL_STACK.ERROR_NUMBER(i), 5, '0') || ' ' ||
                    UTL_CALL_STACK.ERROR_MSG(i) || CHR(10);
            EXCEPTION
            WHEN BAD_DEPTH THEN
                NULL;
            END;
        END LOOP;
        --
        RETURN SUBSTR(out_stack, 1, bug.length_message);
    END;



    FUNCTION get_error_id
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN recent_error_id;
    END;



    FUNCTION get_log_id
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN recent_log_id;
    END;



    FUNCTION get_root_id (
        in_log_id       debug_log.log_id%TYPE := NULL
    )
    RETURN debug_log.log_id%TYPE
    AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        SELECT MIN(NVL(e.log_parent, e.log_id)) INTO out_log_id
        FROM debug_log e
        CONNECT BY PRIOR e.log_parent = e.log_id
        START WITH e.log_id = NVL(in_log_id, recent_log_id);
        --
        RETURN out_log_id;
    END;



    FUNCTION get_tree_id
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN recent_tree_id;
    END;



    PROCEDURE set_tree_id (
        in_log_id       debug_log.log_id%TYPE
    ) AS
    BEGIN
        recent_tree_id := in_log_id;
    END;



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
    RETURN debug_log.arguments%TYPE AS
    BEGIN
        RETURN SUBSTR(RTRIM(
            in_arg1 || bug.splitter ||
            in_arg2 || bug.splitter ||
            in_arg3 || bug.splitter ||
            in_arg4 || bug.splitter ||
            in_arg5 || bug.splitter ||
            in_arg6 || bug.splitter ||
            in_arg7 || bug.splitter ||
            in_arg8, bug.splitter), 1, bug.length_arguments);
    END;



    FUNCTION get_caller_name (
        in_offset           PLS_INTEGER     := 0,
        in_skip_this        BOOLEAN         := TRUE,
        in_attach_line      BOOLEAN         := FALSE
    )
    RETURN debug_log.module_name%TYPE
    AS
        module_name         debug_log.module_name%TYPE;
        offset              PLS_INTEGER                 := NVL(in_offset, 0);
    BEGIN
        -- find first caller before this package
        FOR i IN 2 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP
            module_name := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            --
            IF in_skip_this AND module_name LIKE $$PLSQL_UNIT || '.%' THEN
                CONTINUE;
            END IF;
            --
            IF offset > 0 THEN
                offset := offset - 1;
                CONTINUE;
            END IF;
            --
            RETURN module_name ||
                CASE WHEN in_attach_line THEN bug.splitter || UTL_CALL_STACK.UNIT_LINE(i) END;
        END LOOP;
        --
        RETURN NULL;
    END;



    PROCEDURE get_caller__ (
        in_log_id               debug_log.log_id%TYPE       := NULL,
        in_parent_id            debug_log.log_parent%TYPE   := NULL,
        in_flag                 debug_log.flag%TYPE         := NULL,
        out_module_name     OUT debug_log.module_name%TYPE,
        out_module_line     OUT debug_log.module_line%TYPE,
        out_parent_id       OUT debug_log.log_parent%TYPE
    )
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    ) AS
        curr_module     debug_log.module_name%TYPE;
        curr_index      debug_log.module_name%TYPE;
        parent_index    debug_log.module_name%TYPE;
    BEGIN
        out_parent_id := in_parent_id;
        --
        FOR i IN 2 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP  -- 2 = ignore this function
            curr_module := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            --
            CONTINUE WHEN
                curr_module LIKE $$PLSQL_UNIT || '.%'       -- skip this package
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL;     -- skip DML queries
            --
            out_module_name     := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            out_module_line     := UTL_CALL_STACK.UNIT_LINE(i);
            curr_index          := (UTL_CALL_STACK.DYNAMIC_DEPTH - i) || '|' || out_module_name;
            parent_index        := curr_index;

            -- map CTX called thru schedulers
            IF UTL_CALL_STACK.DYNAMIC_DEPTH >= i + 1 AND in_parent_id IS NULL THEN
                IF (
                        UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i)) LIKE trigger_ctx
                    AND UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1)) = internal_log_fn
                ) THEN
                    out_module_line := 0;
                    out_parent_id   := NVL(recent_log_id, in_log_id);
                    --
                    RETURN;  -- exit procedure
                END IF;
            END IF;

            -- create child
            IF in_flag IN (bug.flag_action) THEN
                map_actions(curr_index) := in_log_id;
                --
            ELSIF in_flag IN (bug.flag_module, bug.flag_scheduler) THEN
                map_modules(curr_index) := in_log_id;
                
                -- find previous module (on another depth)
                BEGIN
                    parent_index := (UTL_CALL_STACK.DYNAMIC_DEPTH - i - 1) || '|' || UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1));
                EXCEPTION
                WHEN BAD_DEPTH THEN
                    NULL;
                END;
            END IF;

            -- recover parent_id
            IF out_parent_id IS NULL AND map_actions.EXISTS(parent_index) THEN
                out_parent_id := NULLIF(map_actions(parent_index), in_log_id);
            END IF;
            --
            IF out_parent_id IS NULL AND map_modules.EXISTS(parent_index) THEN
                out_parent_id := NULLIF(map_modules(parent_index), in_log_id);
            END IF;
            --
            EXIT;  -- break, we need just first one
        END LOOP;
        --
        out_module_line := NVL(out_module_line, 0);
    END;



    PROCEDURE set_session (
        in_user_id          debug_log.user_id%TYPE,
        in_module_name      debug_log.module_name%TYPE,
        in_action_name      debug_log.action_name%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_IDENTIFIER(in_user_id);                                -- CLIENT_IDENTIFIER
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(in_user_id);                      -- CLIENT_INFO
        --
        IF in_module_name IS NOT NULL THEN
            DBMS_APPLICATION_INFO.SET_MODULE(in_module_name, in_action_name);   -- MODULE, ACTION
        END IF;
        --
        IF in_action_name IS NOT NULL THEN
            DBMS_APPLICATION_INFO.SET_ACTION(in_action_name);                   -- ACTION
        END IF;
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_module,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_module (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_module,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_action,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_action,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_debug,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_debug (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_debug,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_result,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_result (
        in_arg1         debug_log.arguments%TYPE    := NULL,
        in_arg2         debug_log.arguments%TYPE    := NULL,
        in_arg3         debug_log.arguments%TYPE    := NULL,
        in_arg4         debug_log.arguments%TYPE    := NULL,
        in_arg5         debug_log.arguments%TYPE    := NULL,
        in_arg6         debug_log.arguments%TYPE    := NULL,
        in_arg7         debug_log.arguments%TYPE    := NULL,
        in_arg8         debug_log.arguments%TYPE    := NULL
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_result,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_warning,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_warning,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_error,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_error,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        log_id          debug_log.log_id%TYPE;
        action_name     debug_log.action_name%TYPE;
    BEGIN
        action_name     := COALESCE(in_action, bug.get_caller_name(), 'UNEXPECTED_ERROR');
        log_id          := bug.log_error (
            in_action   => action_name,
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
        );
        --
        --RAISE bug.app_exception;
        -- we could raise this^, but without custom message
        -- so we append same code but with message to current err_stack
        -- and we can intercept this code in calls above
        RAISE_APPLICATION_ERROR(bug.app_exception_code, action_name || bug.splitter || log_id, TRUE);
    END;



    PROCEDURE log_context (
        in_namespace        debug_log.arguments%TYPE    := '%',
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            SELECT
                x.namespace || bug.splitter_package ||
                x.attribute || bug.splitter_values || x.value AS key_value_pair
            FROM session_context x
            WHERE x.namespace   LIKE in_namespace
                AND x.attribute LIKE in_filter
            ORDER BY x.namespace, x.attribute
        ) LOOP
            payload := payload || c.key_value_pair || bug.splitter_rows;
        END LOOP;
        --
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_CONTEXT', in_namespace, in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_nls (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            SELECT n.parameter || bug.splitter_values || n.value AS key_value_pair
            FROM nls_session_parameters n
            WHERE n.parameter LIKE in_filter
            ORDER BY n.parameter
        ) LOOP
            payload := payload || c.key_value_pair || bug.splitter_rows;
        END LOOP;
        --
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_NLS', in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_userenv (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            WITH t AS (
                SELECT
                    'CLIENT_IDENTIFIER,CLIENT_INFO,ACTION,MODULE,' ||
                    'CURRENT_SCHEMA,CURRENT_USER,CURRENT_EDITION_ID,CURRENT_EDITION_NAME,' ||
                    'OS_USER,POLICY_INVOKER,' ||
                    'SESSION_USER,SESSIONID,SID,SESSION_EDITION_ID,SESSION_EDITION_NAME,' ||
                    'AUTHENTICATED_IDENTITY,AUTHENTICATION_DATA,AUTHENTICATION_METHOD,IDENTIFICATION_TYPE,' ||
                    'ENTERPRISE_IDENTITY,PROXY_ENTERPRISE_IDENTITY,PROXY_USER,' ||
                    'GLOBAL_CONTEXT_MEMORY,GLOBAL_UID,' ||
                    'AUDITED_CURSORID,ENTRYID,STATEMENTID,CURRENT_SQL,CURRENT_BIND,' ||
                    'HOST,SERVER_HOST,SERVICE_NAME,IP_ADDRESS,' ||
                    'DB_DOMAIN,DB_NAME,DB_UNIQUE_NAME,DBLINK_INFO,DATABASE_ROLE,ISDBA,' ||
                    'INSTANCE,INSTANCE_NAME,NETWORK_PROTOCOL,' ||
                    'LANG,LANGUAGE,NLS_TERRITORY,NLS_CURRENCY,NLS_SORT,NLS_DATE_FORMAT,NLS_DATE_LANGUAGE,NLS_CALENDAR,' ||
                    'BG_JOB_ID,FG_JOB_ID' AS attributes
                FROM DUAL
            )
            SELECT c.name || bug.splitter_values || c.value AS key_value_pair
            FROM (
                SELECT
                    REGEXP_SUBSTR(t.attributes, '[^,]+', 1, LEVEL)                            AS name,
                    SYS_CONTEXT('USERENV', REGEXP_SUBSTR(t.attributes, '[^,]+', 1, LEVEL))    AS value
                FROM t
                CONNECT BY LEVEL <= REGEXP_COUNT(t.attributes, ',')
            ) c
            WHERE c.name LIKE in_filter
            ORDER BY c.name
        ) LOOP
            payload := payload || c.key_value_pair || bug.splitter_rows;
        END LOOP;
        --
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_USERENV', in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_cgi (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            WITH t AS (
                SELECT
                    'QUERY_STRING,AUTHORIZATION,DAD_NAME,DOC_ACCESS_PATH,DOCUMENT_TABLE,' ||
                    'HTTP_ACCEPT,HTTP_ACCEPT_ENCODING,HTTP_ACCEPT_CHARSET,HTTP_ACCEPT_LANGUAGE,' ||
                    'HTTP_COOKIE,HTTP_HOST,HTTP_PRAGMA,HTTP_REFERER,HTTP_USER_AGENT,' ||
                    'PATH_ALIAS,PATH_INFO,REMOTE_ADDR,REMOTE_HOST,REMOTE_USER,' ||
                    'REQUEST_CHARSET,REQUEST_IANA_CHARSET,REQUEST_METHOD,REQUEST_PROTOCOL,' ||
                    'SCRIPT_NAME,SCRIPT_PREFIX,SERVER_NAME,SERVER_PORT,SERVER_PROTOCOL' AS attributes
                FROM DUAL
            )
            SELECT c.name
            FROM (
                SELECT REGEXP_SUBSTR(t.attributes, '[^,]+', 1, LEVEL) AS name
                FROM t
                CONNECT BY LEVEL <= REGEXP_COUNT(t.attributes, ',')
            ) c
            WHERE c.name LIKE in_filter
            ORDER BY c.name
        ) LOOP
            BEGIN
                payload := payload || c.name || bug.splitter_values || OWA_UTIL.GET_CGI_ENV(c.name) || bug.splitter_rows;
            EXCEPTION
            WHEN VALUE_ERROR THEN
                NULL;
            END;
        END LOOP;
        --
        out_log_id := bug.log__ (
            in_action_name  => bug.empty_action,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_CGI', in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_apex_items (
        in_page_id          debug_log.page_id%TYPE      := NULL,
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            FOR c IN (
                SELECT
                    i.item_name                                 AS name,
                    APEX_UTIL.GET_SESSION_STATE(i.item_name)    AS value
                FROM apex_application_page_items i
                WHERE i.application_id  = NV('APP_ID')
                    AND i.page_id       = NVL(in_page_id, NV('APP_PAGE_ID'))
                    AND i.item_name     LIKE in_filter
                ORDER BY i.item_name
            ) LOOP
                payload := payload || c.name || bug.splitter_values || c.value || bug.splitter_rows;
            END LOOP;
            --
            out_log_id := bug.log__ (
                in_action_name  => bug.empty_action,
                in_flag         => bug.flag_info,
                in_arguments    => bug.get_arguments('LOG_APEX_ITEMS', in_page_id, in_filter),
                in_message      => payload
            );
        $ELSE
            NULL;
        $END
    END;



    PROCEDURE log_apex_globals (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            FOR c IN (
                SELECT
                    i.item_name                                 AS name,
                    APEX_UTIL.GET_SESSION_STATE(i.item_name)    AS value
                FROM apex_application_items i
                WHERE i.application_id  = NV('APP_ID')
                    AND i.item_name     LIKE in_filter
                ORDER BY i.item_name
            ) LOOP
                payload := payload || c.name || bug.splitter_values || c.value || bug.splitter_rows;
            END LOOP;
            --
            out_log_id := bug.log__ (
                in_action_name  => bug.empty_action,
                in_flag         => bug.flag_info,
                in_arguments    => bug.get_arguments('LOG_APEX_GLOBALS', in_filter),
                in_message      => payload
            );
        $ELSE
            NULL;
        $END
    END;



    FUNCTION log_scheduler (
        in_scheduler_id     debug_log.log_id%TYPE
    )
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_scheduler,
            in_arguments    => 'LOG_SCHEDULER|' || in_scheduler_id,
            in_parent_id    => in_scheduler_id
        );
    END;



    PROCEDURE log_scheduler (
        in_scheduler_id     debug_log.log_id%TYPE
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_scheduler,
            in_arguments    => 'LOG_SCHEDULER|' || in_scheduler_id,
            in_parent_id    => in_scheduler_id
        );
    END;



    PROCEDURE log_progress (
        in_progress         NUMBER := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        slno                BINARY_INTEGER;
        rec                 debug_log%ROWTYPE;
    BEGIN
        bug.get_caller__ (
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_parent_id       => rec.log_parent
        );

        -- find longops record
        IF NVL(in_progress, 0) = 0 THEN
            -- first visit
            SELECT e.* INTO rec
            FROM debug_log e
            WHERE e.log_id = rec.log_parent;
            --
            rec.scn             := DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS_NOHINT;
            rec.log_parent      := rec.log_id;  -- create fresh child
            rec.log_id          := log_id.NEXTVAL;
            rec.flag            := bug.flag_longops;
            --
            INSERT INTO debug_log
            VALUES rec;
        ELSE
            SELECT e.* INTO rec
            FROM debug_log e
            WHERE e.log_parent  = rec.log_parent
                AND e.flag      = bug.flag_longops;
        END IF;

        -- update progress for system views
        DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS (
            rindex          => rec.scn,
            slno            => slno,
            op_name         => rec.module_name,     -- 64 chars
            target_desc     => rec.action_name,     -- 32 chars
            context         => rec.log_id,
            sofar           => NVL(in_progress, 0),
            totalwork       => 1,                   -- 1 = 100%
            units           => '%'
        );

        -- calculate time spend since start
        rec.timer :=
            LPAD(EXTRACT(HOUR   FROM LOCALTIMESTAMP - rec.created_at), 2, '0') || ':' ||
            LPAD(EXTRACT(MINUTE FROM LOCALTIMESTAMP - rec.created_at), 2, '0') || ':' ||
            RPAD(REGEXP_REPLACE(
                REGEXP_REPLACE(EXTRACT(SECOND FROM LOCALTIMESTAMP - rec.created_at), '^[\.,]', '00,'),
                '^(\d)[\.,]', '0\1,'
            ), 9, '0');

        -- update progress in log
        UPDATE debug_log e
        SET e.scn           = rec.scn,
            e.arguments     = ROUND(in_progress * 100, 2) || '%',
            e.timer         = rec.timer
        WHERE e.log_id      = rec.log_id;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



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
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 debug_log%ROWTYPE;
        map_index           debug_log.module_name%TYPE;
        --
        whitelisted         BOOLEAN := FALSE;   -- force log
        blacklisted         BOOLEAN := FALSE;   -- dont log
    BEGIN
        -- get caller info and parent id
        rec.log_id := log_id.NEXTVAL;
        --
        bug.get_caller__ (
            in_log_id           => rec.log_id,
            in_parent_id        => in_parent_id,
            in_flag             => in_flag,
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_parent_id       => rec.log_parent
        );

        -- recover contexts for scheduler
        IF in_flag = bug.flag_scheduler AND in_parent_id IS NOT NULL THEN
            BEGIN
                SELECT e.user_id, e.action_name, e.contexts
                INTO rec.user_id, rec.action_name, rec.contexts
                FROM debug_log e
                WHERE e.log_id = in_parent_id;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20000, 'SCHEDULER_ROOT_MISSING ' || in_parent_id);
            END;

            -- recover app context values from log and set user
            recent_log_id := rec.log_id;  -- to link CTX calls to proper branch
            ctx.apply_payload(rec.contexts);
            ctx.set_user_id(rec.user_id);
        END IF;

        -- get user and update session info
        rec.user_id         := NVL(rec.user_id, ctx.get_user_id());
        rec.flag            := NVL(in_flag, '?');
        rec.module_line     := NVL(rec.module_line, 0);
        --
        bug.set_session (
            in_user_id      => rec.user_id,
            in_module_name  => rec.module_name,
            in_action_name  => NVL(in_action_name, rec.module_name || bug.splitter || rec.module_line)
        );

        -- override flag for CTX package calls
        IF rec.module_name LIKE trigger_ctx AND rec.flag = bug.flag_module THEN
            rec.flag := bug.flag_context;
        END IF;

        -- force log errors
        IF SQLCODE != 0 OR rec.flag IN (bug.flag_error, bug.flag_warning) THEN
            whitelisted := TRUE;
        END IF;

        -- check whitelist first
        IF NOT whitelisted THEN
            FOR i IN 1 .. rows_whitelist.COUNT LOOP
                EXIT WHEN whitelisted;
                --
                IF rec.user_id              LIKE rows_whitelist(i).user_id
                    AND rec.module_name     LIKE rows_whitelist(i).module_name
                    AND rec.flag            LIKE rows_whitelist(i).flag
                THEN
                    whitelisted := TRUE;
                END IF;
            END LOOP;
        END IF;

        -- check blacklist
        IF NOT whitelisted THEN
            FOR i IN 1 .. rows_blacklist.COUNT LOOP
                EXIT WHEN blacklisted;
                --
                IF rec.user_id              LIKE rows_blacklist(i).user_id
                    AND rec.module_name     LIKE rows_blacklist(i).module_name
                    AND rec.flag            LIKE rows_blacklist(i).flag
                THEN
                    blacklisted := TRUE;
                END IF;
            END LOOP;
            --
            IF blacklisted THEN
                RETURN NULL;  -- exit function
            END IF;
        END IF;

        -- prepare record
        rec.app_id          := NVL(ctx.get_app_id(), 0);  -- default to zero to match contexts table
        rec.page_id         := ctx.get_page_id();
        rec.action_name     := SUBSTR(COALESCE(rec.action_name, in_action_name, bug.empty_action), 1, bug.length_action);
        rec.arguments       := SUBSTR(in_arguments, 1, bug.length_arguments);
        rec.message         := SUBSTR(in_message,   1, bug.length_message);  -- may be overwritten later
        rec.session_db      := ctx.get_session_db();
        rec.session_apex    := ctx.get_session_apex();
        rec.scn             := TIMESTAMP_TO_SCN(SYSDATE);
        rec.created_at      := LOCALTIMESTAMP;

        -- add context values
        IF SQLCODE != 0 OR INSTR(bug.track_contexts, rec.flag) > 0 OR bug.track_contexts = '%' OR rec.flag = bug.flag_scheduler THEN
            rec.contexts := SUBSTR(ctx.get_payload(), 1, bug.length_contexts);
        END IF;

        -- add call stack
        IF SQLCODE != 0 OR INSTR(bug.track_callstack, rec.flag) > 0 OR bug.track_callstack = '%' OR in_parent_id IS NOT NULL THEN
            rec.message := SUBSTR(rec.message || bug.get_call_stack(), 1, bug.length_message);
        END IF;

        -- add error stack if available
        IF SQLCODE != 0 THEN
            rec.action_name := NVL(NULLIF(rec.action_name, bug.empty_action), 'UNKNOWN_ERROR');
            rec.message     := SUBSTR(rec.message || bug.get_error_stack(), 1, bug.length_message);
        END IF;

        -- finally store record in table
        INSERT INTO debug_log VALUES rec;
        COMMIT;
        --
        recent_log_id := rec.log_id;

        -- print message to console
        $IF $$OUTPUT_ENABLED $THEN
            DBMS_OUTPUT.PUT_LINE(
                rec.log_id || ' [' || rec.flag || ']: ' ||
                --RPAD(' ', (rec.module_depth - 1) * 2, ' ') ||
                rec.module_name || ' [' || rec.module_line || '] ' || NULLIF(rec.action_name, bug.empty_action) ||
                RTRIM(': ' || SUBSTR(in_arguments, 1, 40), ': ')
            );
        $END

        bug.start_profilers(rec);

        -- save last error for easy access
        IF SQLCODE != 0 THEN
            recent_error_id := rec.log_id;
        END IF;
        --
        RETURN rec.log_id;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('-- NOT LOGGED ERROR:');
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_CALL_STACK);
        DBMS_OUTPUT.PUT_LINE('-- ^');
        --
        COMMIT;
        RAISE_APPLICATION_ERROR(-20000, 'LOG_FAILED', TRUE);
    END;



    PROCEDURE attach_clob (
        in_payload          CLOB,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    ) AS
        rec                 debug_log_lobs%ROWTYPE;
    BEGIN
        bug.log_module(in_log_id, in_lob_name);
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.log_parent      := NVL(in_log_id, recent_log_id);
        rec.payload_clob    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_clob);
        --
        INSERT INTO debug_log_lobs VALUES rec;
    END;



    PROCEDURE attach_clob (
        in_payload          XMLTYPE,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    ) AS
        rec                 debug_log_lobs%ROWTYPE;
    BEGIN
        bug.log_module(in_log_id, in_lob_name);
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.log_parent      := NVL(in_log_id, recent_log_id);
        rec.payload_clob    := in_payload.GETCLOBVAL();
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_clob);
        --
        INSERT INTO debug_log_lobs VALUES rec;
    END;



    PROCEDURE attach_blob (
        in_payload          BLOB,
        in_lob_name         debug_log_lobs.lob_name%TYPE    := NULL,
        in_log_id           debug_log_lobs.log_id%TYPE      := NULL
    ) AS
        rec                 debug_log_lobs%ROWTYPE;
    BEGIN
        bug.log_module(in_log_id, in_lob_name);
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.log_parent      := NVL(in_log_id, recent_log_id);
        rec.payload_blob    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_blob);
        --
        INSERT INTO debug_log_lobs VALUES rec;
    END;



    PROCEDURE start_profilers (
        rec                 debug_log%ROWTYPE
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        -- avoid infinite loop
        IF rec.flag = bug.flag_profiler THEN
            RETURN;
        END IF;
        --
        $IF $$PROFILER_INSTALLED $THEN
            FOR i IN 1 .. rows_profiler.COUNT LOOP
                IF rows_profiler(i).profiler    = 'Y'
                    AND rec.user_id             LIKE rows_profiler(i).user_id
                    AND rec.module_name         LIKE rows_profiler(i).module_name
                THEN
                    DBMS_PROFILER.START_PROFILER(rec.log_id, run_number => curr_profiler_id);
                    $IF $$OUTPUT_ENABLED $THEN
                        DBMS_OUTPUT.PUT_LINE('  > START_PROFILER ' || curr_profiler_id);
                    $END
                    --
                    out_log_id := bug.log__ (                   -- be aware that this may cause infinite loop
                        in_action_name  => 'START_PROFILER',    -- used in debug_log_profiler view
                        in_flag         => bug.flag_profiler,
                        in_arguments    => curr_profiler_id,
                        in_parent_id    => rec.log_id
                    );
                    --
                    curr_profiler_id    := rec.log_id;          -- store current and parent log_id so we can stop profiler later
                    parent_profiler_id  := rec.log_parent;
                    --
                    EXIT;  -- one profiler is enough
                END IF;
            END LOOP;
        $END
        --
        /*
        $IF $$PROFILER_INSTALLED OR $$COVERAGE_INSTALLED $THEN
            IF rec.flag IN (bug.flag_module, bug.flag_context) AND rec.flag != bug.flag_profiler THEN
                FOR i IN 1 .. rows_profiler.COUNT LOOP
                    IF rec.user_id              LIKE rows_profiler(i).user_id
                        AND rec.module_name     LIKE rows_profiler(i).module_name
                    THEN
                        $IF $$COVERAGE_INSTALLED $THEN
                            IF rows_profiler(i).coverage = 'Y' THEN
                                curr_coverage_id := DBMS_PLSQL_CODE_COVERAGE.START_COVERAGE(rec.log_id);
                                $IF $$OUTPUT_ENABLED $THEN
                                    DBMS_OUTPUT.PUT_LINE('  > START_COVERAGE ' || curr_coverage_id);
                                $END
                                --
                                bug.log__ (         -- be aware that this may cause infinite loop
                                    in_action_name  => 'START_COVERAGE',    -- used in debug_log_profiler view
                                    in_flag         => bug.flag_profiler,
                                    in_arguments    => curr_coverage_id,
                                    in_parent_id    => rec.log_id
                                );
                                --
                                curr_coverage_id    := rec.log_id;      -- store current and parent log_id so we can stop coverage later
                                parent_coverage_id  := rec.log_parent;
                                --
                                EXIT;
                            END IF;
                        $END
                    END IF;
                END LOOP;
            END IF;
        $END*/
        --
        NULL;
    END;



    PROCEDURE stop_profilers (
        in_log_id           debug_log.log_id%TYPE := NULL
    ) AS
    BEGIN
        $IF $$PROFILER_INSTALLED $THEN
            IF in_log_id IN (curr_profiler_id, parent_profiler_id) THEN
                $IF $$OUTPUT_ENABLED $THEN
                    DBMS_OUTPUT.PUT_LINE('  > STOP_PROFILER');
                $END
                DBMS_PROFILER.STOP_PROFILER;
            END IF;
        $END
        --
        /*
        $IF $$COVERAGE_INSTALLED $THEN
            IF in_log_id IN (curr_coverage_id, parent_coverage_id) THEN
                $IF $$OUTPUT_ENABLED $THEN
                    DBMS_OUTPUT.PUT_LINE('  > STOP_COVERAGE');
                $END
                DBMS_PLSQL_CODE_COVERAGE.STOP_COVERAGE;
            END IF;
        $END*/
        --
        NULL;
    END;



    PROCEDURE update_timer (
        in_log_id           debug_log.log_id%TYPE := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 debug_log%ROWTYPE;
    BEGIN
        IF in_log_id IS NULL THEN
            bug.get_caller__ (
                in_parent_id        => in_log_id,
                out_module_name     => rec.module_name,
                out_module_line     => rec.module_line,
                out_parent_id       => rec.log_parent
            );
        END IF;

        -- when updating timer for same module which initiated start_profilers
        bug.stop_profilers(NVL(in_log_id, rec.log_parent));

        -- update timer
        UPDATE debug_log e
        SET e.timer =
            LPAD(EXTRACT(HOUR   FROM LOCALTIMESTAMP - e.created_at), 2, '0') || ':' ||
            LPAD(EXTRACT(MINUTE FROM LOCALTIMESTAMP - e.created_at), 2, '0') || ':' ||
            RPAD(REGEXP_REPLACE(
                REGEXP_REPLACE(EXTRACT(SECOND FROM LOCALTIMESTAMP - e.created_at), '^[\.,]', '00,'),
                '^(\d)[\.,]', '0\1,'
            ), 9, '0')
        WHERE e.log_id = NVL(in_log_id, rec.log_parent);
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



    FUNCTION get_dml_query (
        in_log_id           debug_log.log_id%TYPE,
        in_table_name       debug_log.module_name%TYPE,
        in_table_rowid      VARCHAR2,
        in_action           CHAR  -- [I|U|D]
    )
    RETURN debug_log_lobs.payload_clob%TYPE
    AS
        out_query           VARCHAR2(32767);
        in_cursor           SYS_REFCURSOR;
    BEGIN
        -- prepare cursor for XML conversion and extraction
        OPEN in_cursor FOR
            'SELECT * FROM ' || bug.dml_tables_owner || '.' || in_table_name || bug.dml_tables_postfix ||
            ' WHERE ora_err_tag$ = ' || in_log_id;

        -- build query the way you can run it again manually or run just inner select to view passed values
        -- to see dates properly setup nls_date_format first
        -- ALTER SESSION SET nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
        SELECT
            'MERGE INTO ' || LOWER(in_table_name) || ' t' || CHR(10) ||
            'USING (' || CHR(10) ||
            --
            '    SELECT' || CHR(10) ||
            LISTAGG('        ''' || p.value || ''' AS ' || LOWER(p.name) || p.data_type, CHR(10) ON OVERFLOW TRUNCATE)
                WITHIN GROUP (ORDER BY p.pos) || CHR(10) ||
            '        ''' || in_table_rowid || ''' AS rowid_' || CHR(10) ||
            '    FROM DUAL' ||
            --
            CASE WHEN in_table_rowid IS NOT NULL THEN
                CHR(10) || '    UNION ALL' || CHR(10) ||
                '    SELECT' || CHR(10) ||
                LISTAGG('        TO_CHAR(' || LOWER(p.name), '),' || CHR(10) ON OVERFLOW TRUNCATE)
                    WITHIN GROUP (ORDER BY p.pos) || '),' || CHR(10) ||
                '        ''^'' AS rowid_' || CHR(10) ||  -- remove ROWID to match only on 1 row
                '    FROM ' || LOWER(in_table_name) || CHR(10) ||
                '    WHERE ROWID = ''' || in_table_rowid || ''''
                END || CHR(10) ||
            --
            ') s ON (s.rowid_ = t.ROWID)' || CHR(10) ||
            --
            CASE in_action
                WHEN 'U' THEN
                    'WHEN MATCHED' || CHR(10) ||
                    'THEN UPDATE SET' || CHR(10) ||
                    LISTAGG('    t.' || LOWER(p.name) || ' = s.' || LOWER(p.name), ',' || CHR(10) ON OVERFLOW TRUNCATE)
                        WITHIN GROUP (ORDER BY p.pos)
                WHEN 'I' THEN
                    'WHEN NOT MATCHED' || CHR(10) ||
                    'THEN INSERT (' || CHR(10) ||
                    LISTAGG('    t.' || LOWER(p.name), ',' || CHR(10) ON OVERFLOW TRUNCATE)
                        WITHIN GROUP (ORDER BY p.pos) || CHR(10) || ')' || CHR(10) ||
                    'VALUES (' || CHR(10) ||
                    LISTAGG('    ''' || p.value || '''', ',' || CHR(10) ON OVERFLOW TRUNCATE)
                        WITHIN GROUP (ORDER BY p.pos) || CHR(10) || ')'
            END || ';'
        INTO out_query
        FROM (
            SELECT
                VALUE(p).GETROOTELEMENT()       AS name,
                EXTRACTVALUE(VALUE(p), '/*')    AS value,
                c.column_id                     AS pos,
                c.data_type
            FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(in_cursor), '//ROWSET/ROW/*'))) p
            JOIN (
                SELECT
                    c.table_name, c.column_name, c.column_id,
                    ',  -- ' || CASE
                        WHEN c.data_type LIKE '%CHAR%' OR c.data_type = 'RAW' THEN
                            c.data_type ||
                            DECODE(NVL(c.char_length, 0), 0, '',
                                '(' || c.char_length || DECODE(c.char_used, 'C', ' CHAR', '') || ')'
                            )
                        WHEN c.data_type = 'NUMBER' AND c.data_precision = 38 THEN 'INTEGER'
                        WHEN c.data_type = 'NUMBER' THEN
                            c.data_type ||
                            DECODE(NVL(c.data_precision || c.data_scale, 0), 0, '',
                                DECODE(NVL(c.data_scale, 0), 0, '(' || c.data_precision || ')',
                                    '(' || c.data_precision || ',' || c.data_scale || ')'
                                )
                            )
                        ELSE c.data_type
                        END AS data_type
                FROM user_tab_cols c
                WHERE c.table_name = in_table_name
            ) c
                ON c.column_name = VALUE(p).GETROOTELEMENT()
            ORDER BY c.column_id
        ) p;
        --
        CLOSE in_cursor;
        --
        RETURN out_query;
    END;



    PROCEDURE process_dml_error (
        in_log_id           debug_log.log_id%TYPE,
        in_error_table      VARCHAR2,   -- remove references to debug_log_dml_errors view
        in_table_name       VARCHAR2,   -- because it can get invalidated too often
        in_table_rowid      VARCHAR2,
        in_action           VARCHAR2
    ) AS
        payload             debug_log_lobs.payload_clob%TYPE;
        error_id            debug_log_lobs.log_id%TYPE;
    BEGIN
        bug.log_module(in_log_id, in_error_table, in_table_name, in_table_rowid, in_action);
        --
        payload := bug.get_dml_query (
            in_log_id       => in_log_id,
            in_table_name   => in_table_name,
            in_table_rowid  => in_table_rowid,
            in_action       => in_action
        );
        --
        SELECT MIN(e.log_id) INTO error_id  -- find row with actual error
        FROM debug_log e
        WHERE e.created_at      >= TRUNC(SYSDATE)
            AND e.log_parent    = in_log_id
            AND e.flag          = bug.flag_error;
        --
        bug.attach_clob (
            in_payload      => payload,
            in_lob_name     => 'DML_ERROR',
            in_log_id       => NVL(error_id, in_log_id)
        );

        -- remove from DML ERR table
        EXECUTE IMMEDIATE
            'DELETE FROM ' || in_error_table ||
            ' WHERE ora_err_tag$ = ' || in_log_id;
    END;
    



    PROCEDURE drop_dml_tables (
        in_table_like       debug_log.module_name%TYPE
    ) AS
    BEGIN
        bug.log_module(in_table_like);
        --
        FOR c IN (
            SELECT t.owner, t.table_name
            FROM all_tables t
            WHERE t.owner           = bug.dml_tables_owner
                AND t.table_name    LIKE UPPER(in_table_like) || bug.dml_tables_postfix
        ) LOOP
            bug.log_debug(c.table_name, c.owner);
            --
            EXECUTE IMMEDIATE
                'DROP TABLE ' || c.owner || '.' || c.table_name || ' PURGE';
        END LOOP;

        -- refresh view
        bug.create_dml_errors_view();
    END;



    PROCEDURE create_dml_tables (
        in_table_like       debug_log.module_name%TYPE
    ) AS
    BEGIN
        bug.log_module(in_table_like);
        -- process existing data first
        bug_process_dml_errors(in_table_like);  -- it calls bug.process_dml_error

        -- drop existing tables
        bug.drop_dml_tables(in_table_like);

        -- create DML log tables for all tables
        FOR c IN (
            SELECT
                t.table_name                            AS data_table,
                t.table_name || bug.dml_tables_postfix  AS error_table
            FROM user_tables t
            WHERE t.table_name LIKE UPPER(in_table_like)
        ) LOOP
            bug.log_debug(c.data_table, c.error_table);
            --
            DBMS_ERRLOG.CREATE_ERROR_LOG (
                dml_table_name          => USER || '.' || c.data_table,
                err_log_table_owner     => bug.dml_tables_owner,
                err_log_table_name      => c.error_table,
                skip_unsupported        => TRUE
            );
            --
            IF bug.dml_tables_owner != USER THEN
                EXECUTE IMMEDIATE
                    'GRANT ALL ON ' || bug.dml_tables_owner || '.' || c.error_table ||
                    ' TO ' || USER;
            END IF;
        END LOOP;

        -- refresh view
        bug.create_dml_errors_view();
    END;



    PROCEDURE create_dml_errors_view
    AS
        q_block     VARCHAR2(32767);
        q           CLOB;
        comments    DBMS_UTILITY.LNAME_ARRAY;  -- TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(q, TRUE);

        -- backup current comments
        FOR c IN (
            SELECT table_name, column_name, comments
            FROM user_col_comments
            WHERE table_name = bug.view_dml_errors
        ) LOOP
            comments(comments.count) :=
                'COMMENT ON COLUMN ' || c.table_name || '.' || c.column_name ||
                ' IS ''' || REPLACE(c.comments, '''', '''''') || '''';
        END LOOP;

        -- create header with correct data types
        q_block :=
            'CREATE OR REPLACE VIEW ' || bug.view_dml_errors || ' (' ||
            '    log_id, action, table_name, table_rowid, dml_rowid, err_message' || CHR(10) ||
            ') AS' || CHR(10) ||
            'SELECT 0, ''-'', ''-'', ''UROWID'', ROWID, ''-''' || CHR(10) ||
            'FROM DUAL' || CHR(10) ||
            'WHERE ROWNUM = 0' || CHR(10) ||
            '--' || CHR(10) ||
            '-- THIS VIEW IS GENERATED' || CHR(10) ||
            '--' || CHR(10);
        --
        DBMS_LOB.WRITEAPPEND(q, LENGTH(q_block), q_block);
        q_block := '';

        -- append all existing tables
        FOR c IN (
            SELECT
                RTRIM(t.table_name, bug.dml_tables_postfix) AS data_table,
                t.owner || '.' || t.table_name              AS error_table
            FROM all_tables t
            WHERE t.owner           = bug.dml_tables_owner
                AND t.table_name    LIKE '%' || dml_tables_postfix
            ORDER BY 1
        ) LOOP
            q_block := 'UNION ALL' || CHR(10);
            q_block := q_block || 'SELECT' || CHR(10);
            q_block := q_block || '    TO_NUMBER(e.ora_err_tag$),' || CHR(10);
            q_block := q_block || '    e.ora_err_optyp$,' || CHR(10);
            q_block := q_block || '    ''' || c.data_table || ''',' || CHR(10);
            q_block := q_block || '    CAST(e.ora_err_rowid$ AS VARCHAR2(30)),' || CHR(10);
            q_block := q_block || '    e.ROWID,' || CHR(10);
            q_block := q_block || '    e.ora_err_mesg$' || CHR(10);
            q_block := q_block || 'FROM ' || c.error_table || ' e' || CHR(10);
            --
            DBMS_LOB.WRITEAPPEND(q, LENGTH(q_block), q_block);
            q_block := '';
        END LOOP;
        --
        EXECUTE IMMEDIATE q;

        -- add comments
        FOR i IN comments.FIRST .. comments.LAST LOOP
            EXECUTE IMMEDIATE comments(i);
        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        bug.raise_error();
    END;



    PROCEDURE purge_old (
        in_age          PLS_INTEGER := NULL
    ) AS
        partition_date  VARCHAR2(10);   -- YYYY-MM-DD
        count_before    PLS_INTEGER;
        count_after     PLS_INTEGER;
    BEGIN
        bug.log_module(in_age);

        -- purge all
        IF in_age < 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE debug_log_lobs DISABLE CONSTRAINT fk_debug_log_lobs_debug_log';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE debug_log_lobs';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || bug.table_name || ' CASCADE';
            EXECUTE IMMEDIATE 'ALTER TABLE debug_log_lobs ENABLE CONSTRAINT fk_debug_log_lobs_debug_log';
        END IF;

        -- delete old LOBs
        DELETE FROM debug_log_lobs l
        WHERE l.log_id IN (
            SELECT l.log_id
            FROM debug_log e
            JOIN debug_log_lobs l
                ON l.log_parent = e.log_id
            WHERE e.created_at < TRUNC(SYSDATE) - NVL(in_age, bug.table_rows_max_age)
        );
        --
        DELETE FROM debug_log e
        WHERE e.created_at < TRUNC(SYSDATE) - NVL(in_age, bug.table_rows_max_age);

        -- purge whole partitions
        FOR c IN (
            SELECT table_name, partition_name, high_value, partition_position
            FROM user_tab_partitions p
            WHERE p.table_name = bug.table_name
                AND p.partition_position > 1
                AND p.partition_position < (
                    SELECT MAX(partition_position) - NVL(in_age, bug.table_rows_max_age)
                    FROM user_tab_partitions
                    WHERE table_name = bug.table_name
                )
        ) LOOP
            partition_date := SUBSTR(REPLACE(SUBSTR(c.high_value, 1, 100), 'TIMESTAMP'' '), 1, 10);
            --
            EXECUTE IMMEDIATE
                'SELECT COUNT(*) FROM ' || c.table_name INTO count_before;
            --
            EXECUTE IMMEDIATE
                'ALTER TABLE ' || c.table_name ||
                ' DROP PARTITION ' || c.partition_name ||
                ' UPDATE GLOBAL INDEXES';
            --
            EXECUTE IMMEDIATE
                'SELECT COUNT(*) FROM ' || c.table_name INTO count_after;
            --
            IF in_age >= 0 THEN
                bug.log_result(c.partition_name, partition_date, count_before - count_after);
            END IF;
        END LOOP;
    END;

BEGIN

    -- prepare arrays when session starts
    -- load whitelist/blacklist data from logs_tracing table
    SELECT t.*
    BULK COLLECT INTO rows_whitelist
    FROM debug_log_setup t
    WHERE (t.app_id     = ctx.get_app_id() OR t.app_id < 0)
        AND t.track     = 'Y'
        AND ROWNUM      <= rows_limit;
    --
    SELECT t.*
    BULK COLLECT INTO rows_blacklist
    FROM debug_log_setup t
    WHERE (t.app_id     = ctx.get_app_id() OR t.app_id < 0)
        AND t.track     = 'N'
        AND ROWNUM      <= rows_limit;

    -- load profiling requests
    SELECT t.*
    BULK COLLECT INTO rows_profiler
    FROM debug_log_setup t
    WHERE (t.app_id     = ctx.get_app_id() OR t.app_id < 0)
        AND t.track     = 'Y'
        AND (t.profiler = 'Y' OR t.coverage = 'Y')
        AND ROWNUM      <= rows_limit;
END;
/
