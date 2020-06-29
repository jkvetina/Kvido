CREATE OR REPLACE PACKAGE BODY bug AS

    recent_log_id       debug_log.log_id%TYPE;    -- last log_id in session (any flag)
    recent_error_id     debug_log.log_id%TYPE;    -- last real log_id in session (with E flag)
    recent_tree_id      debug_log.log_id%TYPE;    -- selected log_id for LOGS_TREE view

    -- array to hold recent log_id; array[depth + module] = log_id
    TYPE arr_map_module_to_id IS
        TABLE OF debug_log.log_id%TYPE
        INDEX BY debug_log.module_name%TYPE;
    --
    map_modules         arr_map_module_to_id;
    --
    fn_log_module       CONSTANT debug_log.module_name%TYPE     := 'BUG.LOG_MODULE';  -- $$PLSQL_UNIT
    fn_log_action       CONSTANT debug_log.module_name%TYPE     := 'BUG.LOG_ACTION';

    -- module_name LIKE to switch flag_module to flag_context
    trigger_ctx         CONSTANT debug_log.module_name%TYPE     := 'CTX.%';

    -- arrays to specify adhoc requests
    TYPE arr_tracking IS VARRAY(20) OF debug_log_tracking%ROWTYPE;
    --
    rows_whitelist      arr_tracking := arr_tracking();
    rows_blacklist      arr_tracking := arr_tracking();
    --
    rows_limit          CONSTANT PLS_INTEGER := 20;  -- match arr_tracking VARRAY



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
                out_module LIKE $$PLSQL_UNIT || '.LOG__'    -- skip target function
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL;     -- skip DML queries
            --
            out_stack := out_stack || --(UTL_CALL_STACK.DYNAMIC_DEPTH - i + 1) || ') ' ||
                out_module || ' [' || UTL_CALL_STACK.UNIT_LINE(i) || ']' || CHR(10);
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
        in_offset           debug_log.module_depth%TYPE     := 0
    )
    RETURN debug_log.module_name%TYPE
    AS
        module_name         debug_log.module_name%TYPE;
        offset              debug_log.module_depth%TYPE     := NVL(in_offset, 0);
    BEGIN
        -- find first caller before this package
        FOR i IN 1 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP
            module_name := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            --
            IF module_name NOT LIKE $$PLSQL_UNIT || '.%' THEN
                IF offset > 0 THEN
                    offset := offset - 1;
                    CONTINUE;
                END IF;
                --
                RETURN module_name;
            END IF;
        END LOOP;
        --
        RETURN NULL;
    END;



    PROCEDURE get_caller_info (
        out_module_name     OUT debug_log.module_name%TYPE,
        out_module_line     OUT debug_log.module_line%TYPE,
        out_module_depth    OUT debug_log.module_depth%TYPE,
        out_parent_id       OUT debug_log.log_parent%TYPE
    ) AS
        curr_module             debug_log.module_name%TYPE;
        curr_index              debug_log.module_name%TYPE;
        parent_index            debug_log.module_name%TYPE;
    BEGIN
        -- better version of DBMS_UTILITY.FORMAT_CALL_STACK
        FOR i IN REVERSE 2 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP  -- 2 = ignore this function
            curr_module := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            CONTINUE WHEN
                curr_module LIKE $$PLSQL_UNIT || '.LOG__'    -- skip target function
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL;     -- skip DML queries

            -- first call to this package stops the search
            IF curr_module LIKE 'BUG.%' THEN
                -- set current module
                out_module_name     := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1));
                out_module_line     := UTL_CALL_STACK.UNIT_LINE(i + 1);
                out_module_depth    := UTL_CALL_STACK.DYNAMIC_DEPTH - i;
                curr_index          := out_module_depth || '|' || out_module_name;
                parent_index        := curr_index;

                -- create child
                IF curr_module IN (fn_log_module, fn_log_action) THEN
                    set_caller_module (
                        in_map_index    => curr_index,
                        in_log_id       => recent_log_id
                    );

                    -- recover parent index
                    BEGIN
                        parent_index := (UTL_CALL_STACK.DYNAMIC_DEPTH - i - 1) || '|' || UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 2));
                    EXCEPTION
                    WHEN BAD_DEPTH THEN
                        NULL;
                    END;
                END IF;

                -- recover parent_id
                IF map_modules.EXISTS(parent_index) THEN
                    out_parent_id := NULLIF(map_modules(parent_index), recent_log_id);
                END IF;
                --
                EXIT;  -- break
            END IF;
        END LOOP;
    END;



    PROCEDURE set_caller_module (
        in_map_index    debug_log.module_name%TYPE,
        in_log_id       debug_log.log_id%TYPE
    ) AS
    BEGIN
        map_modules(in_map_index) := in_log_id;
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
        out_log_id := bug.log_module (
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
        );
    END;



    PROCEDURE log_module (
        in_scheduler_id     debug_log.log_id%TYPE
    ) AS
        rec_user_id         debug_log.user_id%TYPE;
        rec_action_name     debug_log.action_name%TYPE;
        rec_contexts        debug_log.contexts%TYPE;
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        SELECT e.user_id, e.action_name, e.contexts
        INTO rec_user_id, rec_action_name, rec_contexts
        FROM debug_log e
        WHERE e.log_id = in_scheduler_id;

        -- recover app context values from log and set user
        ctx.apply_contexts(rec_contexts);
        ctx.set_user_id(rec_user_id);

        -- create log as the last action in this procedure
        out_log_id := bug.log__ (
            in_action_name  => rec_action_name,
            in_flag         => bug.flag_module,
            in_arguments    => rec_action_name || '_' || in_scheduler_id,
            in_parent_id    => in_scheduler_id
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
        out_log_id := bug.log_action (
            in_action   => in_action,
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
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
            in_action_name  => NULL,
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
        out_log_id := bug.log_debug (
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
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
        out_log_id := bug.log_result (
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
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
        out_log_id := bug.log_warning (
            in_action   => in_action,
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
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
        out_log_id := bug.log_error (
            in_action   => in_action,
            in_arg1     => in_arg1,
            in_arg2     => in_arg2,
            in_arg3     => in_arg3,
            in_arg4     => in_arg4,
            in_arg5     => in_arg5,
            in_arg6     => in_arg6,
            in_arg7     => in_arg7,
            in_arg8     => in_arg8
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
        out_log_id      debug_log.log_id%TYPE;
        out_action      debug_log.action_name%TYPE;
    BEGIN
        out_action := COALESCE(in_action, bug.get_caller_name(1), 'UNEXPECTED_ERROR');
        out_log_id := bug.log_error (
            in_action   => out_action,
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
        RAISE_APPLICATION_ERROR(bug.app_exception_code, out_action || bug.splitter || out_log_id, TRUE);
    END;



    FUNCTION log_context (
        in_namespace        debug_log.arguments%TYPE    := '%',
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE AS
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
        RETURN bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_CONTEXT', in_namespace, in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_context (
        in_namespace        debug_log.arguments%TYPE    := '%',
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log_context (
            in_namespace    => in_namespace,
            in_filter       => in_filter
        );
    END;



    FUNCTION log_userenv (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE AS
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
        RETURN bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_USERENV', in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_userenv (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log_userenv (
            in_filter       => in_filter
        );
    END;



    FUNCTION log_cgi (
        in_filter           debug_log.arguments%TYPE    := '%'
    )
    RETURN debug_log.log_id%TYPE AS
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
        RETURN bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_info,
            in_arguments    => bug.get_arguments('LOG_CGI', in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_cgi (
        in_filter           debug_log.arguments%TYPE    := '%'
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log_cgi (
            in_filter       => in_filter
        );
    END;



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
    RETURN debug_log.log_id%TYPE AS
    BEGIN
        RETURN bug.log__ (
            in_action_name  => in_action,
            in_flag         => bug.flag_scheduler,
            in_arguments    => bug.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
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
        rec             debug_log%ROWTYPE;
        map_index       debug_log.module_name%TYPE;
        --
        whitelisted     BOOLEAN := FALSE;   -- force log
        blacklisted     BOOLEAN := FALSE;   -- dont log
    BEGIN
        -- get caller info and parent id
        rec.log_id              := log_id.NEXTVAL;
        recent_log_id           := rec.log_id;
        --
        bug.get_caller_info (   -- basically who called this
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_module_depth    => rec.module_depth,
            out_parent_id       => rec.log_parent
        );
        --
        IF in_parent_id IS NOT NULL THEN
            rec.log_parent      := in_parent_id;
        END IF;

        -- get user and update session info
        rec.user_id         := ctx.get_user_id();
        rec.flag            := COALESCE(in_flag, '?');
        --
        bug.set_session (
            in_user_id      => rec.user_id,
            in_module_name  => rec.module_name,
            in_action_name  => NVL(in_action_name, rec.module_line)
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
                IF bug.output_enabled THEN
                    DBMS_OUTPUT.PUT_LINE('^BLACKLISTED');
                END IF;
                --
                RETURN NULL;  -- exit function
            END IF;
        END IF;

        -- prepare record
        rec.app_id          := ctx.get_app_id();
        rec.page_id         := ctx.get_page_id();
        rec.action_name     := SUBSTR(NVL(in_action_name, bug.empty_action), 1, bug.length_action);
        rec.arguments       := SUBSTR(in_arguments, 1, bug.length_arguments);
        rec.message         := SUBSTR(in_message,   1, bug.length_message);  -- may be overwritten later
        rec.session_db      := ctx.get_session_db();
        rec.session_apex    := ctx.get_session_apex();
        rec.scn             := TIMESTAMP_TO_SCN(SYSDATE);
        rec.created_at      := LOCALTIMESTAMP;

        -- add context values
        IF SQLCODE != 0 OR INSTR(bug.track_contexts, rec.flag) > 0 OR bug.track_contexts = '%' THEN
            rec.contexts := SUBSTR(ctx.get_payload(), 1, bug.length_contexts);
        END IF;

        -- store current contexts before running scheduler
        IF rec.flag = bug.flag_scheduler THEN
            rec.contexts := SUBSTR(ctx.get_payload(), 1, bug.length_contexts);
        END IF;

        -- add call stack
        IF SQLCODE != 0 OR INSTR(bug.track_callstack, rec.flag) > 0 OR bug.track_callstack = '%' THEN
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

        -- print message to console
        IF bug.output_enabled THEN
            DBMS_OUTPUT.PUT_LINE(
                rec.log_id || ' [' || rec.flag || ']: ' ||
                RPAD(' ', (rec.module_depth - 1) * 2, ' ') ||
                rec.module_name || ' [' || rec.module_line || '] ' || NULLIF(rec.action_name, bug.empty_action) ||
                RTRIM(': ' || SUBSTR(in_arguments, 1, 40), ': ')
            );
        END IF;

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
    ) AS
        out_log_id          debug_log.log_id%TYPE;
    BEGIN
        out_log_id := bug.log__ (
            in_action_name  => in_action_name,
            in_flag         => in_flag,
            in_arguments    => in_arguments,
            in_message      => in_message,
            in_parent_id    => in_parent_id
        );
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
        rec.parent_log      := NVL(in_log_id, recent_log_id);
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
        rec.parent_log      := NVL(in_log_id, recent_log_id);
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
        rec.parent_log      := NVL(in_log_id, recent_log_id);
        rec.payload_blob    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_blob);
        --
        INSERT INTO debug_log_lobs VALUES rec;
    END;



    PROCEDURE update_timer (
        in_log_id           debug_log.log_id%TYPE := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 debug_log%ROWTYPE;
    BEGIN
        IF in_log_id IS NULL THEN
            bug.get_caller_info (   -- basically who called this
                out_module_name     => rec.module_name,
                out_module_line     => rec.module_line,
                out_module_depth    => rec.module_depth,
                out_parent_id       => rec.log_parent
            );
        END IF;
        --
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



    PROCEDURE update_progress (
        in_progress         NUMBER := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        slno                BINARY_INTEGER;
        rec                 debug_log%ROWTYPE;
    BEGIN
        bug.get_caller_info (   -- basically who called this
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_module_depth    => rec.module_depth,
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



    PROCEDURE update_message (
        in_log_id           debug_log.log_id%TYPE,
        in_message          debug_log.message%TYPE
    ) AS
    BEGIN
        bug.log__ (
            in_action_name  => NULL,
            in_flag         => bug.flag_query,
            in_arguments    => NULL,
            in_message      => in_message,
            in_parent_id    => in_log_id
        );
    END;



    FUNCTION get_dml_tracker
    RETURN VARCHAR2 AS
    BEGIN
        RETURN recent_log_id || ' ' || bug.get_caller_name();
    END;



    PROCEDURE purge_old AS
        partition_date  VARCHAR2(10);   -- YYYY-MM-DD
        count_before    PLS_INTEGER;
        count_after     PLS_INTEGER;
    BEGIN
        bug.log_module();

        -- delete old LOBs
        DELETE FROM debug_log_lobs l
        WHERE l.log_id IN (
            SELECT l.log_id
            FROM debug_log e
            JOIN debug_log_lobs l
                ON l.parent_log = e.log_id
            WHERE e.created_at < TRUNC(SYSDATE) - bug.table_rows_max_age
        );

        -- purge whole partitions
        FOR c IN (
            SELECT table_name, partition_name, high_value, partition_position
            FROM user_tab_partitions p
            WHERE p.table_name = bug.table_name
                AND p.partition_position > 1
                AND p.partition_position < (
                    SELECT MAX(partition_position) - bug.table_rows_max_age
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
            bug.log_result(c.partition_name, partition_date, count_before, count_after);
        END LOOP;
    END;

BEGIN

    -- prepare collections when session starts
    -- load whitelist/blacklist data from logs_tracing table
    SELECT t.*
    BULK COLLECT INTO rows_whitelist
    FROM debug_log_tracking t
    WHERE t.track   = 'Y'
        AND ROWNUM  <= rows_limit;
    --
    SELECT t.*
    BULK COLLECT INTO rows_blacklist
    FROM debug_log_tracking t
    WHERE t.track   = 'N'
        AND ROWNUM  <= rows_limit;

END;
/

