CREATE OR REPLACE PACKAGE BODY tree AS

    recent_log_id           logs.log_id%TYPE;    -- last log_id in session (any flag)
    recent_error_id         logs.log_id%TYPE;    -- last real log_id in session (with E flag)
    recent_tree_id          logs.log_id%TYPE;    -- selected log_id for LOGS_TREE view

    -- array to hold recent log_id; array[depth + module] = log_id
    TYPE arr_map_module_to_id IS
        TABLE OF logs.log_id%TYPE
        INDEX BY logs.module_name%TYPE;
    --
    map_modules             arr_map_module_to_id;
    map_actions             arr_map_module_to_id;

    -- module_name LIKE to switch flag_module to flag_session
    trigger_sess            CONSTANT logs.module_name%TYPE      := 'SESS.%';

    internal_log_fn         CONSTANT logs.module_name%TYPE      := 'TREE.LOG__';
    internal_update_timer   CONSTANT logs.module_name%TYPE      := 'TREE.UPDATE_TIMER';

    -- arrays to specify adhoc requests
    rows_whitelist          arr_log_setup := arr_log_setup();
    rows_blacklist          arr_log_setup := arr_log_setup();
    --
    rows_limit              CONSTANT PLS_INTEGER                := 100;  -- match arr_log_setup VARRAY

    -- possible exception when parsing call stack
    BAD_DEPTH EXCEPTION;
    PRAGMA EXCEPTION_INIT(BAD_DEPTH, -64610);



    FUNCTION get_call_stack
    RETURN logs.message%TYPE
    AS
        out_stack       VARCHAR2(32767);
        out_module      VARCHAR2(100);
    BEGIN
        -- better version of DBMS_UTILITY.FORMAT_CALL_STACK
        FOR i IN REVERSE 2 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP  -- 2 = ignore this function
            out_module := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            /*
            CONTINUE WHEN
                UTL_CALL_STACK.OWNER(i) != tree.dml_tables_owner                -- different user (APEX)
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL                          -- skip DML queries
                OR REGEXP_LIKE(out_module, 'UT(\.|_[A-Z0-9_]*\.)[A-Z0-9_]+')    -- skip unit tests
                OR (out_module = internal_log_fn AND i <= 2);                   -- skip target function
            */
            CONTINUE WHEN UTL_CALL_STACK.OWNER(i) IS NULL;
            --
            out_stack := out_stack || out_module || ' [' || UTL_CALL_STACK.UNIT_LINE(i) || ']' || CHR(10);
        END LOOP;
        --
        RETURN SUBSTR(out_stack, 1, tree.length_message);
    END;



    FUNCTION get_error_stack
    RETURN logs.message%TYPE
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
        RETURN SUBSTR(out_stack, 1, tree.length_message);
    END;



    FUNCTION get_error_id
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN recent_error_id;
    END;



    FUNCTION get_log_id
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN recent_log_id;
    END;



    FUNCTION get_root_id (
        in_log_id       logs.log_id%TYPE        := NULL
    )
    RETURN logs.log_id%TYPE
    AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        SELECT MIN(COALESCE(e.log_parent, e.log_id)) INTO out_log_id
        FROM logs e
        CONNECT BY PRIOR e.log_parent = e.log_id
        START WITH e.log_id = COALESCE(in_log_id, recent_log_id);
        --
        RETURN out_log_id;
    END;



    FUNCTION get_tree_id
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN recent_tree_id;
    END;



    PROCEDURE set_tree_id (
        in_log_id       logs.log_id%TYPE
    ) AS
    BEGIN
        recent_tree_id := in_log_id;
    END;



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
    RETURN logs.arguments%TYPE AS
    BEGIN
        RETURN SUBSTR(
            NULLIF(REGEXP_REPLACE(
                REGEXP_REPLACE(
                    NULLIF(JSON_ARRAY(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8 NULL ON NULL), '[]'),
                    '"(\d+)([.,]\d+)?"', '\1\2'  -- convert to numbers if possible
                ),
                '(,null)+\]$', ']'),
                '[null]'),
            1, tree.length_arguments);
    END;



    FUNCTION get_caller_name (
        in_offset           PLS_INTEGER     := 0,
        in_skip_this        BOOLEAN         := TRUE,
        in_attach_line      BOOLEAN         := FALSE
    )
    RETURN logs.module_name%TYPE
    AS
        module_name         logs.module_name%TYPE;
        offset              PLS_INTEGER                 := COALESCE(in_offset, 0);
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
                CASE WHEN in_attach_line THEN tree.splitter || UTL_CALL_STACK.UNIT_LINE(i) END;
        END LOOP;
        --
        RETURN NULL;
    END;



    PROCEDURE get_caller__ (
        in_log_id               logs.log_id%TYPE        := NULL,
        in_parent_id            logs.log_parent%TYPE    := NULL,
        in_flag                 logs.flag%TYPE          := NULL,
        out_module_name     OUT logs.module_name%TYPE,
        out_module_line     OUT logs.module_line%TYPE,
        out_parent_id       OUT logs.log_parent%TYPE
    )
    ACCESSIBLE BY (
        PACKAGE tree,
        PACKAGE tree_ut
    ) AS
        curr_module     logs.module_name%TYPE;
        curr_index      logs.module_name%TYPE;
        parent_index    logs.module_name%TYPE;
        next_module     logs.module_name%TYPE;
        prev_module     logs.module_name%TYPE;
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
            --
            BEGIN
                next_module     := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1));
                prev_module     := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i - 1));
            EXCEPTION
            WHEN BAD_DEPTH THEN
                NULL;
            END;

            -- map SESS called thru schedulers
            IF UTL_CALL_STACK.DYNAMIC_DEPTH >= i + 1 AND in_parent_id IS NULL THEN
                IF (out_module_name LIKE trigger_sess AND next_module = internal_log_fn) THEN
                    out_module_line := 0;
                    out_parent_id   := COALESCE(recent_log_id, in_log_id);
                    --
                    RETURN;  -- exit procedure
                END IF;
            END IF;

            -- create child
            IF in_flag IN (tree.flag_action) THEN
                map_actions(curr_index) := in_log_id;
                --
            ELSIF in_flag IN (tree.flag_module, tree.flag_scheduler) THEN
                map_modules(curr_index) := in_log_id;

                -- find previous module (on another depth)
                parent_index := (UTL_CALL_STACK.DYNAMIC_DEPTH - i - 1) || '|' || next_module;
            END IF;

            -- fix tree.update_timer, it must updates M flags and not A flags
            IF in_log_id IS NULL AND prev_module = tree.internal_update_timer THEN
                -- recover log_id only from map_modules
                IF out_parent_id IS NULL AND map_modules.EXISTS(parent_index) THEN
                    out_parent_id := NULLIF(map_modules(parent_index), in_log_id);
                END IF;
                --
                EXIT;  -- break
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
        out_module_line := COALESCE(out_module_line, 0);
    END;



    PROCEDURE set_session (
        in_module_name      logs.module_name%TYPE,
        in_action_name      logs.action_name%TYPE
    ) AS
    BEGIN
        IF in_module_name IS NOT NULL THEN
            DBMS_APPLICATION_INFO.SET_MODULE(in_module_name, in_action_name);   -- USERENV.MODULE, ACTION
        END IF;
        --
        IF in_action_name IS NOT NULL THEN
            DBMS_APPLICATION_INFO.SET_ACTION(in_action_name);                   -- ACTION
        END IF;
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_module,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_module (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_module,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_action,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_action,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_debug,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_debug (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_debug,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_result,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE log_result (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => tree.empty_action,
            in_flag         => tree.flag_result,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_warning,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_warning,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_error,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



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
    ) AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => in_action,
            in_flag         => tree.flag_error,
            in_arguments    => tree.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
        );
    END;



    PROCEDURE raise_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL,
        --
        in_rollback     BOOLEAN                 := FALSE,
        in_to_apex      BOOLEAN                 := FALSE
    ) AS
        log_id          logs.log_id%TYPE;
        action_name     logs.action_name%TYPE;
    BEGIN
        IF in_rollback THEN
            ROLLBACK;
        END IF;
        --
        action_name     := COALESCE(in_action, tree.get_caller_name(), 'UNEXPECTED_ERROR');
        log_id          := tree.log_error (
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

        -- send error message to APEX
        $IF $$APEX_INSTALLED $THEN
        IF in_to_apex THEN
            tree.raise_to_apex (
                in_message  => action_name
            );
        END IF;
        $END

        --RAISE tree.app_exception;
        -- we could raise this^, but without custom message
        -- so we append same code but with message to current err_stack
        -- and we can intercept this code in calls above
        RAISE_APPLICATION_ERROR(tree.app_exception_code, action_name || tree.splitter || log_id, TRUE);
    END;



    PROCEDURE raise_to_apex (
        in_message          logs.message%TYPE
    ) AS
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            APEX_ERROR.ADD_ERROR (
                p_message           => in_message,
                p_display_location  => APEX_ERROR.C_ON_ERROR_PAGE
            );
        $ELSE
            NULL;
        $END
    END;



    PROCEDURE log_context (
        in_namespace        logs.arguments%TYPE     := '%',
        in_filter           logs.arguments%TYPE     := '%'
    ) AS
        out_log_id          logs.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            SELECT
                x.namespace || tree.splitter_package ||
                x.attribute || tree.splitter_values || x.value AS key_value_pair
            FROM session_context x
            WHERE x.namespace   LIKE in_namespace
                AND x.attribute LIKE in_filter
            ORDER BY x.namespace, x.attribute
        ) LOOP
            payload := payload || c.key_value_pair || tree.splitter_rows;
        END LOOP;
        --
        out_log_id := tree.log__ (
            in_action_name  => 'LOG_CONTEXT',
            in_flag         => tree.flag_info,
            in_arguments    => tree.get_arguments(in_namespace, in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_nls (
        in_filter           logs.arguments%TYPE     := '%'
    ) AS
        out_log_id          logs.log_id%TYPE;
        payload             VARCHAR2(32767);
    BEGIN
        FOR c IN (
            SELECT n.parameter || tree.splitter_values || n.value AS key_value_pair
            FROM nls_session_parameters n
            WHERE n.parameter LIKE in_filter
            ORDER BY n.parameter
        ) LOOP
            payload := payload || c.key_value_pair || tree.splitter_rows;
        END LOOP;
        --
        out_log_id := tree.log__ (
            in_action_name  => 'LOG_NLS',
            in_flag         => tree.flag_info,
            in_arguments    => tree.get_arguments(in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_userenv (
        in_filter           logs.arguments%TYPE     := '%'
    ) AS
        out_log_id          logs.log_id%TYPE;
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
            SELECT c.name || tree.splitter_values || c.value AS key_value_pair
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
            payload := payload || c.key_value_pair || tree.splitter_rows;
        END LOOP;
        --
        out_log_id := tree.log__ (
            in_action_name  => 'LOG_USERENV',
            in_flag         => tree.flag_info,
            in_arguments    => tree.get_arguments(in_filter),
            in_message      => payload
        );
    END;



    PROCEDURE log_cgi (
        in_filter           logs.arguments%TYPE     := '%'
    ) AS
        out_log_id          logs.log_id%TYPE;
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
                payload := payload || c.name || tree.splitter_values || OWA_UTIL.GET_CGI_ENV(c.name) || tree.splitter_rows;
            EXCEPTION
            WHEN VALUE_ERROR THEN
                NULL;
            END;
        END LOOP;
        --
        out_log_id := tree.log__ (
            in_action_name  => 'LOG_CGI',
            in_flag         => tree.flag_info,
            in_arguments    => tree.get_arguments(in_filter),
            in_message      => payload
        );
    END;



    FUNCTION log_scheduler (
        in_log_id           logs.log_id%TYPE
    )
    RETURN logs.log_id%TYPE AS
    BEGIN
        RETURN tree.log__ (
            in_action_name  => 'LOG_SCHEDULER',
            in_flag         => tree.flag_scheduler,
            in_arguments    => in_log_id,
            in_parent_id    => in_log_id
        );
    END;



    PROCEDURE log_scheduler (
        in_log_id           logs.log_id%TYPE
    ) AS
        out_log_id          logs.log_id%TYPE;
    BEGIN
        out_log_id := tree.log__ (
            in_action_name  => 'LOG_SCHEDULER',
            in_flag         => tree.flag_scheduler,
            in_arguments    => in_log_id,
            in_parent_id    => in_log_id
        );
    END;



    PROCEDURE start_scheduler (
        in_job_name     VARCHAR2,
        in_statement    VARCHAR2        := NULL,
        in_comments     VARCHAR2        := NULL,
        in_priority     PLS_INTEGER     := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        log_id          logs.log_id%TYPE;
    BEGIN
        log_id := tree.log__ (
            in_action_name  => 'START_SCHEDULER',
            in_flag         => tree.flag_module,
            in_arguments    => tree.get_arguments(in_job_name, in_comments, in_priority),
            in_message      => in_statement,
            in_parent_id    => tree.recent_log_id
        );
        --
        sess.create_session (
            in_user_id => USER
        );
        --
        DBMS_SCHEDULER.CREATE_JOB (
            in_job_name,
            job_type        => 'PLSQL_BLOCK',
            job_action      => 'BEGIN' || CHR(10) ||
                               '    tree.log_scheduler(' || log_id || ');' || CHR(10) ||
                               '    ' || in_statement || CHR(10) ||
                               '    tree.update_timer();' || CHR(10) ||
                               'EXCEPTION' || CHR(10) ||
                               'WHEN OTHERS THEN' || CHR(10) ||
                               '    tree.raise_error();' || CHR(10) ||
                               'END;',
            start_date      => SYSDATE,
            enabled         => FALSE,
            auto_drop       => TRUE,
            comments        => in_comments
        );
        --
        IF in_priority IS NOT NULL THEN
            DBMS_SCHEDULER.SET_ATTRIBUTE(in_job_name, 'JOB_PRIORITY', in_priority);
        END IF;
        --
        DBMS_SCHEDULER.ENABLE(in_job_name);
        COMMIT;
        --
        tree.update_timer(log_id);
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'START_SCHEDULER_FAILED');
    END;



    PROCEDURE log_progress (
        in_progress         NUMBER          := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        slno                BINARY_INTEGER;
        rec                 logs%ROWTYPE;
    BEGIN
        tree.get_caller__ (
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_parent_id       => rec.log_parent
        );

        -- find longops record
        IF COALESCE(in_progress, 0) = 0 THEN
            -- first visit
            SELECT e.* INTO rec
            FROM logs e
            WHERE e.log_id = rec.log_parent;
            --
            rec.message         := DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS_NOHINT;    -- rindex
            rec.log_parent      := rec.log_id;  -- create fresh child
            rec.log_id          := log_id.NEXTVAL;
            rec.flag            := tree.flag_longops;
            --
            INSERT INTO logs
            VALUES rec;
        ELSE
            SELECT e.* INTO rec
            FROM logs e
            WHERE e.log_parent  = rec.log_parent
                AND e.flag      = tree.flag_longops;
        END IF;

        -- update progress for system views
        DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS (
            rindex          => rec.message,
            slno            => slno,
            op_name         => rec.module_name,     -- 64 chars
            target_desc     => rec.action_name,     -- 32 chars
            context         => rec.log_id,
            sofar           => COALESCE(in_progress, 0),
            totalwork       => 1,                   -- 1 = 100%
            units           => '%'
        );

        -- update progress in log
        UPDATE logs e
        SET e.message       = rec.message,
            e.arguments     = ROUND(in_progress * 100, 2) || '%',
            e.timer         = tree.get_timestamp_diff(rec.created_at)
        WHERE e.log_id      = rec.log_id;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



    FUNCTION log__ (
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE,
        in_arguments        logs.arguments%TYPE     := NULL,
        in_message          logs.message%TYPE       := NULL,
        in_parent_id        logs.log_parent%TYPE    := NULL
    )
    RETURN logs.log_id%TYPE
    ACCESSIBLE BY (
        PACKAGE tree,
        PACKAGE tree_ut
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs%ROWTYPE;
        map_index           logs.module_name%TYPE;
        --
        whitelisted         BOOLEAN := FALSE;   -- TRUE = log
        blacklisted         BOOLEAN := FALSE;   -- TRUE = dont log; whitelisted > blacklisted
    BEGIN
        -- get caller info and parent id
        rec.log_id := log_id.NEXTVAL;
        --
        tree.get_caller__ (
            in_log_id           => rec.log_id,
            in_parent_id        => in_parent_id,
            in_flag             => in_flag,
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_parent_id       => rec.log_parent
        );

        -- recover contexts for scheduler
        IF in_flag = tree.flag_scheduler AND in_parent_id IS NOT NULL THEN
            BEGIN
                SELECT e.user_id INTO rec.user_id
                FROM logs e
                WHERE e.log_id = in_parent_id;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SCHEDULER_ROOT_MISSING ' || in_parent_id, TRUE);
            END;

            -- recover app context values from log and set user
            recent_log_id := rec.log_id;  -- to link SESS calls to proper branch
            sess.create_session (
                in_user_id      => rec.user_id
            );
        END IF;

        -- get user and update session info
        rec.user_id         := COALESCE(rec.user_id, sess.get_user_id());
        rec.flag            := COALESCE(in_flag, '?');
        rec.module_line     := COALESCE(rec.module_line, 0);
        --
        tree.set_session (
            in_module_name  => rec.module_name,
            in_action_name  => COALESCE(in_action_name, rec.module_name || tree.splitter || rec.module_line)
        );

        -- override flags for APEX calls
        IF rec.module_name LIKE trigger_sess AND rec.flag = tree.flag_module AND rec.module_name IN (
            'SESS.CREATE_SESSION',
            'SESS.UPDATE_SESSION'
        ) THEN
            --rec.arguments   := SUBSTR(in_arguments, 1, tree.length_arguments);
            --rec.action_name := REGEXP_SUBSTR(rec.arguments, '^\[\"([^\"]+)\"', 1, 1, NULL, 1);
            --rec.arguments   := REGEXP_REPLACE(rec.arguments, '^\[\"([^\"]+)\",?', '[');
            --
            IF in_arguments LIKE '["ON_LOAD:BEFORE_HEADER%' THEN
                rec.flag            := tree.flag_apex_page;
                curr_page_log_id    := NULL;
            ELSIF in_arguments LIKE '["ON_SUBMIT%' THEN
                rec.flag            := tree.flag_apex_form;
            END IF;
        END IF;

        -- fill log_id from recent page visit
        rec.log_parent := NVL(rec.log_parent, curr_page_log_id);

        -- use first argument as action_name for anonymous calls
        IF rec.flag = tree.flag_module AND rec.module_name = '__anonymous_block' THEN
            rec.action_name := SUBSTR(COALESCE(REGEXP_SUBSTR(in_arguments, '^\["([^"]+)', 1, 1, NULL, 1), tree.empty_action), 1, tree.length_action);
        END IF;

        -- override flag for triggers
        IF rec.flag = tree.flag_module AND rec.module_name LIKE '%\_\_' ESCAPE '\' THEN
            rec.flag := tree.flag_trigger;
        END IF;

        -- force log errors
        IF SQLCODE != 0 OR rec.flag IN (tree.flag_error, tree.flag_warning) THEN
            whitelisted := TRUE;
        END IF;

        -- check whitelist first
        IF NOT whitelisted THEN
            whitelisted := tree.is_listed (
                in_list => rows_whitelist,
                in_row  => rec
            );
        END IF;

        -- check blacklist
        IF NOT whitelisted THEN
            blacklisted := tree.is_listed (
                in_list => rows_blacklist,
                in_row  => rec
            );
            --
            IF blacklisted THEN
                RETURN NULL;  -- exit function
            END IF;
        END IF;

        -- prepare record
        rec.app_id          := sess.get_app_id();
        rec.page_id         := sess.get_page_id();
        rec.action_name     := SUBSTR(COALESCE(rec.action_name, in_action_name, tree.empty_action), 1, tree.length_action);
        rec.arguments       := SUBSTR(COALESCE(rec.arguments, in_arguments), 1, tree.length_arguments);
        rec.message         := SUBSTR(in_message,   1, tree.length_message);  -- may be overwritten later
        rec.session_id      := sess.get_session_id();
        rec.created_at      := SYSTIMESTAMP;
        rec.today           := TO_CHAR(SYSDATE, 'YYYY-MM-DD');

        -- add call stack
        IF SQLCODE != 0 OR INSTR(tree.track_callstack, rec.flag) > 0 OR tree.track_callstack = '%' OR in_parent_id IS NOT NULL THEN
            rec.message := SUBSTR(rec.message || tree.get_call_stack(), 1, tree.length_message);
        END IF;

        -- add error stack if available
        IF SQLCODE != 0 THEN
            rec.action_name := COALESCE(NULLIF(rec.action_name, tree.empty_action), 'UNKNOWN_ERROR');
            rec.message     := SUBSTR(rec.message || tree.get_error_stack(), 1, tree.length_message);
        END IF;

        /*
        IF rec.flag = 'W' THEN
            rec.timer := tree.get_timestamp_diff(curr_page_stamp, rec.created_at);
        END IF;
        */

        -- finally store record in table
        INSERT INTO logs VALUES rec;
        COMMIT;
        --
        recent_log_id := rec.log_id;
        IF SQLCODE != 0 OR rec.flag = tree.flag_error THEN
            recent_error_id := rec.log_id;  -- save last error for easy access
        END IF;

        -- print message to console
        IF apex.is_developer() THEN
            DBMS_OUTPUT.PUT_LINE(
                rec.log_id || ' ^' || COALESCE(rec.log_parent, 0) || ' [' || rec.flag || ']: ' ||
                --RPAD(' ', (rec.module_depth - 1) * 2, ' ') ||
                rec.module_name || ' [' || rec.module_line || '] ' || NULLIF(rec.action_name, tree.empty_action) ||
                RTRIM(': ' || SUBSTR(in_arguments, 1, 40), ': ')
            );
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
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'LOG_FAILED', TRUE);
    END;



    FUNCTION is_listed (
        in_list         arr_log_setup,
        in_row          logs%ROWTYPE
    )
    RETURN BOOLEAN AS
    BEGIN
        FOR i IN 1 .. in_list.COUNT LOOP
            IF (in_row.module_name  LIKE in_list(i).module_name OR in_list(i).module_name   IS NULL)
                AND (in_row.flag    = in_list(i).flag           OR in_list(i).flag          IS NULL)
            THEN
                RETURN TRUE;
            END IF;
        END LOOP;
        --
        RETURN FALSE;
    END;



    PROCEDURE attach_blob (
        in_payload          logs_lobs.payload_blob%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        rec.log_parent      := COALESCE(in_log_id, tree.log_module(in_log_id, in_lob_name));
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.payload_blob    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_blob);
        --
        INSERT INTO logs_lobs VALUES rec;
        COMMIT;
    END;



    PROCEDURE attach_clob (
        in_payload          logs_lobs.payload_clob%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        rec.log_parent      := COALESCE(in_log_id, tree.log_module(in_log_id, in_lob_name));
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.payload_clob    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_clob);
        --
        INSERT INTO logs_lobs VALUES rec;
        COMMIT;
    END;



    PROCEDURE attach_xml (
        in_payload          logs_lobs.payload_xml%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        rec.log_parent      := COALESCE(in_log_id, tree.log_module(in_log_id, in_lob_name));
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.payload_xml     := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(XMLTYPE.GETCLOBVAL(rec.payload_xml));
        --
        INSERT INTO logs_lobs VALUES rec;
        COMMIT;
    END;



    PROCEDURE attach_json (
        in_payload          logs_lobs.payload_json%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        rec.log_parent      := COALESCE(in_log_id, tree.log_module(in_log_id, in_lob_name));
        --
        rec.log_id          := log_id.NEXTVAL;
        rec.payload_json    := in_payload;
        rec.lob_name        := in_lob_name;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.payload_json);
        --
        INSERT INTO logs_lobs VALUES rec;
        COMMIT;
    END;



    FUNCTION get_timestamp_diff (
        in_start        TIMESTAMP,
        in_end          TIMESTAMP       := NULL
    )
    RETURN logs.timer%TYPE AS
    BEGIN
        RETURN COALESCE(in_end, SYSTIMESTAMP) - in_start;
    END;



    PROCEDURE update_timer (
        in_log_id           logs.log_id%TYPE        := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs%ROWTYPE;
    BEGIN
        IF in_log_id IS NULL THEN
            tree.get_caller__ (
                in_parent_id        => in_log_id,
                out_module_name     => rec.module_name,
                out_module_line     => rec.module_line,
                out_parent_id       => rec.log_parent
            );
        END IF;

        -- update timer
        UPDATE logs l
        SET l.timer = tree.get_timestamp_diff(l.created_at)
        WHERE l.log_id = COALESCE(in_log_id, rec.log_parent);
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



    PROCEDURE update_trigger (
        in_log_id               logs.log_id%TYPE,
        in_rows_inserted        NUMBER          := NULL,
        in_rows_updated         NUMBER          := NULL,
        in_rows_deleted         NUMBER          := NULL,
        in_last_rowid           VARCHAR2        := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- update timer
        UPDATE logs l
        SET l.timer = tree.get_timestamp_diff(l.created_at),
            l.arguments = REGEXP_REPLACE(
                tree.get_arguments(
                    CASE WHEN in_rows_inserted > 0 THEN 'INSERTED:' || in_rows_inserted END,
                    CASE WHEN in_rows_inserted = 1 THEN in_last_rowid END,
                    --
                    CASE WHEN in_rows_updated  > 0 THEN 'UPDATED:'  || in_rows_updated  END,
                    CASE WHEN in_rows_updated  = 1 THEN in_last_rowid END,
                    --
                    CASE WHEN in_rows_deleted  > 0 THEN 'DELETED:'  || in_rows_deleted  END,
                    CASE WHEN in_rows_deleted  = 1 THEN in_last_rowid END
                ),
                '^\[(null,)+', '[')
        WHERE l.log_id  = in_log_id;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



    FUNCTION get_dml_query (
        in_log_id           logs.log_id%TYPE,
        in_table_name       logs.module_name%TYPE,
        in_table_rowid      VARCHAR2,
        in_action           CHAR  -- [I|U|D]
    )
    RETURN logs_lobs.payload_clob%TYPE
    AS
        out_query           VARCHAR2(32767);
        in_cursor           SYS_REFCURSOR;
    BEGIN
        -- prepare cursor for XML conversion and extraction
        OPEN in_cursor FOR
            'SELECT * FROM ' || tree.dml_tables_owner || '.' || in_table_name || tree.dml_tables_postfix ||
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
                            DECODE(COALESCE(c.char_length, 0), 0, '',
                                '(' || c.char_length || DECODE(c.char_used, 'C', ' CHAR', '') || ')'
                            )
                        WHEN c.data_type = 'NUMBER' AND c.data_precision = 38 THEN 'INTEGER'
                        WHEN c.data_type = 'NUMBER' THEN
                            c.data_type ||
                            DECODE(COALESCE(TO_NUMBER(c.data_precision || c.data_scale), 0), 0, '',
                                DECODE(COALESCE(c.data_scale, 0), 0, '(' || c.data_precision || ')',
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
        in_log_id           logs.log_id%TYPE,
        in_error_table      VARCHAR2,   -- remove references to logs_dml_errors view
        in_table_name       VARCHAR2,   -- because it can get invalidated too often
        in_table_rowid      VARCHAR2,
        in_action           VARCHAR2
    ) AS
        payload             logs_lobs.payload_clob%TYPE;
        error_id            logs_lobs.log_id%TYPE;
    BEGIN
        tree.log_module(in_log_id, in_error_table, in_table_name, in_table_rowid, in_action);
        --
        payload := tree.get_dml_query (
            in_log_id       => in_log_id,
            in_table_name   => in_table_name,
            in_table_rowid  => in_table_rowid,
            in_action       => in_action
        );
        --
        SELECT MIN(e.log_id) INTO error_id  -- find row with actual error
        FROM logs e
        WHERE e.created_at      >= TRUNC(SYSDATE)
            AND e.log_parent    = in_log_id
            AND e.flag          = tree.flag_error;
        --
        tree.attach_clob (
            in_payload      => payload,
            in_lob_name     => 'DML_ERROR',
            in_log_id       => COALESCE(error_id, in_log_id)
        );

        -- remove from DML ERR table
        EXECUTE IMMEDIATE
            'DELETE FROM ' || in_error_table ||
            ' WHERE ora_err_tag$ = ' || in_log_id;
    END;




    PROCEDURE drop_dml_tables (
        in_table_like       logs.module_name%TYPE
    ) AS
    BEGIN
        tree.log_module(in_table_like);
        --
        FOR c IN (
            SELECT t.owner, t.table_name
            FROM all_tables t
            WHERE t.owner           = tree.dml_tables_owner
                AND t.table_name    LIKE UPPER(in_table_like) || tree.dml_tables_postfix
        ) LOOP
            tree.log_debug(c.table_name, c.owner);
            --
            EXECUTE IMMEDIATE
                'DROP TABLE ' || c.owner || '.' || c.table_name || ' PURGE';
        END LOOP;

        -- refresh view
        tree.create_dml_errors_view();
    END;



    PROCEDURE create_dml_tables (
        in_table_like       logs.module_name%TYPE
    ) AS
    BEGIN
        tree.log_module(in_table_like);

        -- process existing data first, dynamically to avoid compilation errors
        EXECUTE IMMEDIATE
            'BEGIN process_dml_errors(:table_name); END;'
            USING in_table_like;  -- it calls tree.process_dml_error

        -- drop existing tables
        tree.drop_dml_tables(in_table_like);

        -- create DML log tables for all tables
        FOR c IN (
            SELECT
                t.table_name                            AS data_table,
                t.table_name || tree.dml_tables_postfix  AS error_table
            FROM user_tables t
            WHERE t.table_name LIKE UPPER(in_table_like)
        ) LOOP
            tree.log_debug(c.data_table, c.error_table);
            --
            DBMS_ERRLOG.CREATE_ERROR_LOG (
                dml_table_name          => USER || '.' || c.data_table,
                err_log_table_owner     => tree.dml_tables_owner,
                err_log_table_name      => c.error_table,
                skip_unsupported        => TRUE
            );
            --
            IF tree.dml_tables_owner != USER THEN
                EXECUTE IMMEDIATE
                    'GRANT ALL ON ' || tree.dml_tables_owner || '.' || c.error_table ||
                    ' TO ' || USER;
            END IF;
        END LOOP;

        -- refresh view
        tree.create_dml_errors_view();
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
            WHERE table_name = tree.view_dml_errors
        ) LOOP
            comments(comments.count) :=
                'COMMENT ON COLUMN ' || c.table_name || '.' || c.column_name ||
                ' IS ''' || REPLACE(c.comments, '''', '''''') || '''';
        END LOOP;

        -- create header with correct data types
        q_block :=
            'CREATE OR REPLACE VIEW ' || tree.view_dml_errors || ' (' ||
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
                RTRIM(t.table_name, tree.dml_tables_postfix)    AS data_table,
                t.owner || '.' || t.table_name                  AS error_table
            FROM all_tables t
            WHERE t.owner           = tree.dml_tables_owner
                AND t.table_name    LIKE '%' || dml_tables_postfix
            ORDER BY 1
            --
            -- @TODO: JSON
            --
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
        tree.raise_error();
    END;



    PROCEDURE purge_old (
        in_age          PLS_INTEGER         := NULL
    ) AS
        data_exists     PLS_INTEGER;
    BEGIN
        tree.log_module(in_age);

        -- purge all
        IF in_age < 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE logs_lobs DISABLE CONSTRAINT fk_logs_lobs_logs';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE sessions';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE logs_events';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE logs_lobs';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || tree.table_name || ' CASCADE';
            EXECUTE IMMEDIATE 'ALTER TABLE logs_lobs ENABLE CONSTRAINT fk_logs_lobs_logs';
        END IF;

        -- remove old sessions
        DELETE FROM sessions s
        WHERE s.created_at < TRUNC(SYSDATE) - NVL(in_age, tree.table_rows_max_age);
        --
        COMMIT;  -- to reduce UNDO violations

        -- delete old LOBs
        DELETE FROM logs_lobs l
        WHERE l.log_id IN (
            SELECT l.log_id
            FROM logs e
            JOIN logs_lobs l
                ON l.log_parent = e.log_id
            WHERE e.created_at < TRUNC(SYSDATE) - COALESCE(in_age, tree.table_rows_max_age)
        );
        --
        COMMIT;  -- to reduce UNDO violations

        -- remove old partitions
        FOR c IN (
            SELECT p.table_name, p.partition_name
            FROM user_tab_partitions p,
                -- trick to convert LONG to VARCHAR2 on the fly
                XMLTABLE('/ROWSET/ROW'
                    PASSING (DBMS_XMLGEN.GETXMLTYPE(
                        'SELECT p.high_value'                                       || CHR(10) ||
                        'FROM user_tab_partitions p'                                || CHR(10) ||
                        'WHERE p.table_name = ''' || p.table_name || ''''           || CHR(10) ||
                        '    AND p.partition_name = ''' || p.partition_name || ''''
                    ))
                    COLUMNS high_value VARCHAR2(4000) PATH 'HIGH_VALUE'
                ) h
            WHERE p.table_name = tree.table_name
                AND TO_DATE(REGEXP_SUBSTR(h.high_value, '(\d{4}-\d{2}-\d{2})'), 'YYYY-MM-DD') < TRUNC(SYSDATE) - COALESCE(in_age, tree.table_rows_max_age)
        ) LOOP
            -- delete old data in batches
            FOR i IN 1 .. 10 LOOP
                EXECUTE IMMEDIATE
                    'DELETE FROM ' || c.table_name ||
                    ' PARTITION (' || c.partition_name || ') WHERE ROWNUM < 100000';
                --
                COMMIT;  -- to reduce UNDO violations
            END LOOP;

            -- check if data in partition exists
            EXECUTE IMMEDIATE
                'SELECT COUNT(*) FROM ' || c.table_name ||
                ' PARTITION (' || c.partition_name || ') WHERE ROWNUM = 1'
                INTO data_exists;
            --
            IF data_exists = 0 THEN
                EXECUTE IMMEDIATE
                    'ALTER TABLE ' || c.table_name ||
                    ' DROP PARTITION ' || c.partition_name || ' UPDATE GLOBAL INDEXES';
            END IF;
        END LOOP;
        --
        -- SHRINK TOO ???
        COMMIT;
    END;



    PROCEDURE delete_children (
        in_log_id           logs.log_id%TYPE
    ) AS
        rows_to_delete      arr_logs_log_id;
    BEGIN
        SELECT l.log_id
        BULK COLLECT INTO rows_to_delete
        FROM logs l
        CONNECT BY PRIOR l.log_id   = l.log_parent
        START WITH l.log_id         = in_log_id;
        --
        FORALL i IN rows_to_delete.FIRST .. rows_to_delete.LAST
        DELETE FROM logs_lobs
        WHERE log_id = rows_to_delete(i);
        --
        FORALL i IN rows_to_delete.FIRST .. rows_to_delete.LAST
        DELETE FROM logs
        WHERE log_id = rows_to_delete(i);
    END;



    PROCEDURE delete_tree (
        in_log_id           logs.log_id%TYPE
    ) AS
        rows_to_delete      arr_logs_log_id;
    BEGIN
        SELECT l.log_id
        BULK COLLECT INTO rows_to_delete
        FROM logs l
        CONNECT BY PRIOR l.log_id   = l.log_parent
        START WITH l.log_id         = tree.get_root_id(in_log_id);
        --
        FORALL i IN rows_to_delete.FIRST .. rows_to_delete.LAST
        DELETE FROM logs_lobs
        WHERE log_id = rows_to_delete(i);
        --
        FORALL i IN rows_to_delete.FIRST .. rows_to_delete.LAST
        DELETE FROM logs
        WHERE log_id = rows_to_delete(i);
    END;



    FUNCTION log_event (
        in_event_id         logs_events.event_id%TYPE,
        in_event_value      logs_events.event_value%TYPE    := NULL
    )
    RETURN logs_events.log_id%TYPE
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        is_active           events.is_active%TYPE;
        rec                 logs_events%ROWTYPE;
    BEGIN
        rec.app_id          := sess.get_app_id();
        rec.event_id        := in_event_id;

        -- check if event is active
        BEGIN
            SELECT 'Y' INTO is_active
            FROM events e
            WHERE e.app_id          = rec.app_id
                AND e.event_id      = rec.event_id
                AND e.is_active     = 'Y';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        END;

        -- store in event table
        rec.log_id          := log_id.NEXTVAL;
        rec.log_parent      := recent_log_id;
        rec.event_value     := in_event_value;
        rec.user_id         := sess.get_user_id();
        rec.page_id         := sess.get_page_id();
        rec.session_id      := sess.get_session_id();
        rec.created_at      := SYSDATE;
        --
        INSERT INTO logs_events VALUES rec;
        COMMIT;
        --
        RETURN rec.log_id;
    END;



    PROCEDURE log_event (
        in_event_id         logs_events.event_id%TYPE,
        in_event_value      logs_events.event_value%TYPE    := NULL
    ) AS
        out_log_id          logs_events.log_id%TYPE;
    BEGIN
        out_log_id := tree.log_event (
            in_event_id     => in_event_id,
            in_event_value  => in_event_value
        );
    END;



    PROCEDURE init AS
        is_dev              CONSTANT logs_setup.is_dev%TYPE     := CASE WHEN apex.is_developer()    THEN 'Y' ELSE 'N' END;
        is_debug            CONSTANT logs_setup.is_debug%TYPE   := CASE WHEN apex.is_debug()        THEN 'Y' ELSE 'N' END;
    BEGIN
        -- clear maps
        map_modules := arr_map_module_to_id();
        map_actions := arr_map_module_to_id();
        --DBMS_SESSION.RESET_PACKAGE;

        -- load whitelist/blacklist data from logs_tracing table
        -- prepare arrays when session starts
        -- this block is initialized with every APEX request
        -- so user_id and page_id, debug mode wont change until next request
        SELECT t.*
        BULK COLLECT INTO rows_whitelist
        FROM logs_setup t
        WHERE t.app_id          = sess.get_app_id()
            AND (t.user_id      = sess.get_user_id()    OR t.user_id    IS NULL)
            AND (t.page_id      = sess.get_page_id()    OR t.page_id    IS NULL)
            AND (t.is_dev       = is_dev                OR t.is_dev     IS NULL)
            AND (t.is_debug     = is_debug              OR t.is_debug   IS NULL)
            AND t.is_tracked    = 'Y'
            AND ROWNUM          <= rows_limit;
        --
        SELECT t.*
        BULK COLLECT INTO rows_blacklist
        FROM logs_setup t
        WHERE t.app_id          = sess.get_app_id()
            AND (t.user_id      = sess.get_user_id()    OR t.user_id    IS NULL)
            AND (t.page_id      = sess.get_page_id()    OR t.page_id    IS NULL)
            AND (t.is_dev       = is_dev                OR t.is_dev     IS NULL)
            AND (t.is_debug     = is_debug              OR t.is_debug   IS NULL)
            AND t.is_tracked    = 'N'
            AND ROWNUM          <= rows_limit;
    END;

BEGIN
    init();
END;
/
