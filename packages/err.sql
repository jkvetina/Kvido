CREATE OR REPLACE PACKAGE BODY err AS

    recent_log_id       logs.log_id%TYPE;    -- last log_id in session (any flag)
    recent_error_id     logs.log_id%TYPE;    -- last real log_id in session (with E flag)
    recent_tree_id      logs.log_id%TYPE;    -- selected log_id for LOGS_TREE view

    -- array to hold recent log_id; array[depth + module] = log_id
    TYPE arr_map_module_to_id IS
        TABLE OF logs.log_id%TYPE
        INDEX BY logs.module_name%TYPE;
    --
    map_modules         arr_map_module_to_id;
    map_actions         arr_map_module_to_id;
    --
    fn_log_module       CONSTANT logs.module_name%TYPE := 'ERR.LOG_MODULE';
    fn_log_action       CONSTANT logs.module_name%TYPE := 'ERR.LOG_ACTION';
    fn_update_timer     CONSTANT logs.module_name%TYPE := 'ERR.UPDATE_TIMER';

    -- arrays to specify adhoc requests
    TYPE arr_tracking IS VARRAY(20) OF logs_tracking%ROWTYPE;
    --
    rows_whitelist      arr_tracking := arr_tracking();
    rows_blacklist      arr_tracking := arr_tracking();
    --
    rows_limit          CONSTANT PLS_INTEGER := 20;  -- match arr_tracking VARRAY



    -- possible exception when parsing call stack
    BAD_DEPTH EXCEPTION;
    PRAGMA EXCEPTION_INIT(BAD_DEPTH, -64610);

    -- rename anonymous block in call stack
    anonymous_block         CONSTANT VARCHAR2(30) := '__anonymous_block';
    anonymous_block_short   CONSTANT VARCHAR2(30) := '> BLOCK';



    FUNCTION get_call_stack
    RETURN logs.message%TYPE
    AS
        out_stack       VARCHAR2(32767);
        out_module      logs.module_name%TYPE;
    BEGIN
        -- better version of DBMS_UTILITY.FORMAT_CALL_STACK
        FOR i IN REVERSE 1 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP
            out_module := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            CONTINUE WHEN
                out_module LIKE $$PLSQL_UNIT || '.%'        -- skip this package
                OR UTL_CALL_STACK.UNIT_LINE(i) IS NULL;     -- skip DML queries
            --
            out_stack := out_stack ||
                REPLACE(out_module, anonymous_block, anonymous_block_short) ||
                ' [' || UTL_CALL_STACK.UNIT_LINE(i) || ']' || CHR(10);
        END LOOP;

        -- cleanup useless info
        out_stack := REGEXP_REPLACE(out_stack, '\s+DBMS_SQL.EXECUTE [[]\d+[]]\s+> BLOCK [[]\d+[]]', '');
        out_stack := REGEXP_REPLACE(out_stack, '\s+DBMS_SYS_SQL.EXECUTE(.*)', '');
        out_stack := REGEXP_REPLACE(out_stack, '\s+UT(\.|_[A-Z0-9_]*\.)[A-Z0-9_]+ [[]\d+[]]', '');   -- ut/plsql
        --
        RETURN SUBSTR(out_stack, 1, err.length_message);
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
        RETURN SUBSTR(out_stack, 1, err.length_message);
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
        in_log_id       logs.log_id%TYPE := NULL
    )
    RETURN logs.log_id%TYPE
    AS
        out_log_id      logs.log_id%TYPE;
    BEGIN
        SELECT MIN(e.log_id) INTO out_log_id
        FROM logs e
        CONNECT BY PRIOR e.log_parent = e.log_id
        START WITH e.log_id = NVL(in_log_id, recent_log_id);
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
        RETURN SUBSTR(RTRIM(
            in_arg1 || err.splitter ||
            in_arg2 || err.splitter ||
            in_arg3 || err.splitter ||
            in_arg4 || err.splitter ||
            in_arg5 || err.splitter ||
            in_arg6 || err.splitter ||
            in_arg7 || err.splitter ||
            in_arg8, err.splitter), 1, err.length_arguments);
    END;



    FUNCTION get_caller_name (
        in_offset       PLS_INTEGER := NULL
    )
    RETURN logs.module_name%TYPE AS
    BEGIN
        RETURN SUBSTR(REGEXP_SUBSTR(
            UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(2 + NVL(in_offset, 0))),
            '\.(.*)$'), 2);
    EXCEPTION
    WHEN BAD_DEPTH THEN
        RETURN NULL;
    END;



    PROCEDURE get_caller_info (
        out_module_name     OUT logs.module_name%TYPE,
        out_module_line     OUT logs.module_line%TYPE,
        out_module_depth    OUT logs.module_depth%TYPE,
        out_parent_id       OUT logs.log_parent%TYPE
    ) AS
        module_name         logs.module_name%TYPE;
        parent_index        logs.module_name%TYPE;
        parent_offset       PLS_INTEGER                         := 0;
    BEGIN
        -- find first caller before ERR package
        out_module_depth := 0;
        FOR i IN REVERSE 1 .. UTL_CALL_STACK.DYNAMIC_DEPTH LOOP
            module_name := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i));
            IF module_name LIKE $$PLSQL_UNIT || '.%' THEN
                out_module_name := UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1));
                out_module_line := UTL_CALL_STACK.UNIT_LINE(i + 1);

                -- fix purge job
                IF out_module_name = 'jsarunjob' THEN
                    out_module_name     := module_name;
                    out_module_line     := 0;
                    out_module_depth    := 1;
                    RETURN;  -- exit procedure
                END IF;

                -- increase offset for err.module
                IF module_name = fn_log_module THEN
                    parent_offset := 1;
                END IF;
                --
                BEGIN
                    parent_index := (out_module_depth - parent_offset) || err.splitter ||
                        UTL_CALL_STACK.CONCATENATE_SUBPROGRAM(UTL_CALL_STACK.SUBPROGRAM(i + 1 + parent_offset));
                    --
                    IF map_actions.EXISTS(parent_index) AND module_name NOT IN (
                        fn_log_action,
                        fn_update_timer
                    ) THEN
                        out_parent_id := map_actions(parent_index);
                    ELSIF map_modules.EXISTS(parent_index) THEN
                        out_parent_id := map_modules(parent_index);
                    END IF;
                EXCEPTION
                WHEN BAD_DEPTH THEN
                    NULL;
                END;
                --
                RETURN;  -- exit procedure
            END IF;
            --
            out_module_depth := out_module_depth + 1;
        END LOOP;
    END;



    PROCEDURE set_caller_module (
        in_map_index    logs.module_name%TYPE,
        in_log_id       logs.log_id%TYPE
    ) AS
    BEGIN
        map_modules(in_map_index) := in_log_id;
    END;



    PROCEDURE set_caller_action (
        in_map_index    logs.module_name%TYPE,
        in_log_id       logs.log_id%TYPE
    ) AS
    BEGIN
        map_actions(in_map_index) := in_log_id;
    END;



    PROCEDURE set_session (
        in_user_id          logs.user_id%TYPE,
        in_module_name      logs.module_name%TYPE,
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE
    ) AS
    BEGIN
        IF in_flag = err.flag_module THEN
            DBMS_SESSION.SET_IDENTIFIER(in_user_id);                            -- CLIENT_IDENTIFIER
            DBMS_APPLICATION_INFO.SET_CLIENT_INFO(in_user_id);                  -- CLIENT_INFO
            DBMS_APPLICATION_INFO.SET_MODULE(in_module_name, in_action_name);   -- MODULE, ACTION
        ELSIF in_flag = err.flag_action THEN
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
        RETURN err.log__ (
            in_action_name  => err.empty_action,
            in_flag         => err.flag_module,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_module (
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
        RETURN err.log__ (
            in_action_name  => in_action,
            in_flag         => err.flag_action,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_action (
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
        RETURN err.log__ (
            in_action_name  => NULL,
            in_flag         => err.flag_debug,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_debug (
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
        RETURN err.log__ (
            in_action_name  => err.empty_action,
            in_flag         => err.flag_result,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_result (
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
        RETURN err.log__ (
            in_action_name  => in_action,
            in_flag         => err.flag_warning,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_warning (
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
        RETURN err.log__ (
            in_action_name  => in_action,
            in_flag         => err.flag_error,
            in_arguments    => err.get_arguments(in_arg1, in_arg2, in_arg3, in_arg4, in_arg5, in_arg6, in_arg7, in_arg8)
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
        out_log_id := err.log_error (
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
        out_action      logs.action_name%TYPE;
    BEGIN
        out_action := COALESCE(in_action, err.get_caller_name(1), 'UNEXPECTED_ERROR');
        out_log_id := err.log_error (
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
        RAISE_APPLICATION_ERROR(-20000, out_action || err.splitter || out_log_id, TRUE);
    END;



    FUNCTION log_context (
        in_namespace        logs.arguments%TYPE     := '%',
        in_filter           logs.arguments%TYPE     := '%'
    )
    RETURN logs.log_id%TYPE AS
        out_arguments   logs.arguments%TYPE;
    BEGIN
        FOR c IN (
            SELECT x.namespace || '.' || x.attribute || ' = ' || x.value AS key_value_pair
            FROM session_context x
            WHERE x.namespace   LIKE in_namespace
                AND x.attribute LIKE in_filter
            ORDER BY x.namespace, x.attribute
        ) LOOP
            out_arguments := out_arguments || c.key_value_pair || CHR(10);
        END LOOP;
        --
        RETURN err.log__ (
            in_action_name  => NULL,
            in_flag         => err.flag_info,
            in_arguments    => out_arguments
        );
    END;



    PROCEDURE log_context (
        in_namespace        logs.arguments%TYPE     := '%',
        in_filter           logs.arguments%TYPE     := '%'
    ) AS
        out_log_id          logs.log_id%TYPE;
    BEGIN
        out_log_id := err.log_context (
            in_namespace    => in_namespace,
            in_filter       => in_filter
        );
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
        PACKAGE err,
        PACKAGE err_ut
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec             logs%ROWTYPE;
        map_index       logs.module_name%TYPE;
        --
        whitelisted     BOOLEAN := FALSE;   -- force log
        blacklisted     BOOLEAN := FALSE;   -- dont log
    BEGIN
        -- get previous caller info for error tree and session views
        err.get_caller_info (  -- basically who called this
            out_module_name     => rec.module_name,
            out_module_line     => rec.module_line,
            out_module_depth    => rec.module_depth,
            out_parent_id       => rec.log_parent
        );
        --
        rec.log_id        := log_id.NEXTVAL;
        rec.log_parent    := NVL(in_parent_id, rec.log_parent);

        -- store map to build tree
        IF in_flag = err.flag_module THEN
            set_caller_module (
                in_map_index    => rec.module_depth || err.splitter || rec.module_name,
                in_log_id       => rec.log_id
            );
            rec.module_depth := rec.module_depth - 1;  -- fix depth for log
        ELSIF in_flag = err.flag_action THEN
            set_caller_action (
                in_map_index    => rec.module_depth || err.splitter || rec.module_name,
                in_log_id       => rec.log_id
            );
        END IF;

        -- get user and update session info
        rec.user_id := ctx.get_user_id();
        err.set_session (
            in_user_id      => rec.user_id,
            in_module_name  => rec.module_name,
            in_action_name  => NVL(in_action_name, rec.module_line),
            in_flag         => in_flag
        );

        -- force logs errors
        IF SQLCODE != 0 OR in_flag IN (err.flag_error, err.flag_warning) THEN
            whitelisted := TRUE;
        END IF;

        -- check whitelist first
        IF NOT whitelisted THEN
            FOR i IN 1 .. rows_whitelist.COUNT LOOP
                EXIT WHEN whitelisted;
                --
                IF rec.user_id              LIKE rows_whitelist(i).user_id
                    AND rec.module_name     LIKE rows_whitelist(i).module_name
                    AND in_flag             LIKE rows_whitelist(i).flag
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
                    AND in_flag             LIKE rows_blacklist(i).flag
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
        rec.app_id          := ctx.get_app_id();
        rec.page_id         := ctx.get_page_id();
        rec.flag            := COALESCE(in_flag, '?');
        rec.action_name     := SUBSTR(NVL(in_action_name, err.empty_action), 1, err.length_action);
        rec.arguments       := SUBSTR(in_arguments, 1, err.length_arguments);
        rec.message         := SUBSTR(in_message,   1, err.length_message);  -- may be cleared later
        rec.session_db      := ctx.get_session_db();
        rec.session_apex    := ctx.get_session_apex();
        rec.scn             := TIMESTAMP_TO_SCN(SYSDATE);
        rec.created_at      := LOCALTIMESTAMP;

        -- update application contexts
        rec.context_a       := ctx.get_context_a();
        rec.context_b       := ctx.get_context_b();
        rec.context_c       := ctx.get_context_c();

        -- add call stack
        IF SQLCODE != 0 OR INSTR(err.track_callstack, rec.flag) > 0 OR err.track_callstack = '%' THEN
            rec.message := SUBSTR(rec.message || err.get_call_stack(), 1, err.length_message);
        END IF;

        -- add error stack if available
        IF SQLCODE != 0 THEN
            rec.action_name := NVL(NULLIF(rec.action_name, err.empty_action), 'UNKNOWN_ERROR');
            rec.message     := SUBSTR(rec.message || err.get_error_stack(), 1, err.length_message);
        END IF;

        -- finally store record in table
        INSERT INTO logs VALUES rec;
        COMMIT;

        -- print message to console
        IF err.output_enabled THEN
            DBMS_OUTPUT.PUT_LINE(
                rec.log_id || ' [' || rec.flag || ']: ' ||
                RPAD(' ', (rec.module_depth - 1) * 2, ' ') ||
                REPLACE(rec.module_name, anonymous_block, anonymous_block_short) ||
                ' [' || rec.module_line || '] ' || NULLIF(rec.action_name, err.empty_action) ||
                RTRIM(': ' || SUBSTR(in_arguments, 1, 40), ': ')
            );
        END IF;

        -- save last error for easy access
        recent_log_id := rec.log_id;
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
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE,
        in_arguments        logs.arguments%TYPE     := NULL,
        in_message          logs.message%TYPE       := NULL,
        in_parent_id        logs.log_parent%TYPE    := NULL
    )
    ACCESSIBLE BY (
        PACKAGE err,
        PACKAGE err_ut
    ) AS
        out_log_id          logs.log_id%TYPE;
    BEGIN
        out_log_id := err.log__ (
            in_action_name  => in_action_name,
            in_flag         => in_flag,
            in_arguments    => in_arguments,
            in_message      => in_message
        );
    END;



    PROCEDURE attach_clob (
        in_clob             CLOB,
        in_log_id           logs.log_id%TYPE        := NULL
    ) AS
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        err.log_module(in_log_id);
        --
        rec.lob_id          := log_id.NEXTVAL;
        rec.log_id          := NVL(recent_log_id, in_log_id);
        rec.clob_content    := in_clob;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.clob_content);
        --
        INSERT INTO logs_lobs VALUES rec;
    END;



    PROCEDURE attach_clob (
        in_clob             XMLTYPE,
        in_log_id           logs.log_id%TYPE        := NULL
    ) AS
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        err.log_module(in_log_id);
        --
        rec.lob_id          := log_id.NEXTVAL;
        rec.log_id          := NVL(recent_log_id, in_log_id);
        rec.clob_content    := in_clob.GETCLOBVAL();
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.clob_content);
        --
        INSERT INTO logs_lobs VALUES rec;
    END;



    PROCEDURE attach_blob (
        in_blob             BLOB,
        in_log_id           logs.log_id%TYPE        := NULL
    ) AS
        rec                 logs_lobs%ROWTYPE;
    BEGIN
        err.log_module(in_log_id);
        --
        rec.lob_id          := log_id.NEXTVAL;
        rec.log_id          := NVL(recent_log_id, in_log_id);
        rec.blob_content    := in_blob;
        rec.lob_length      := DBMS_LOB.GETLENGTH(rec.blob_content);
        --
        INSERT INTO logs_lobs VALUES rec;
    END;



    PROCEDURE update_timer (
        in_log_id           logs.log_id%TYPE := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 logs%ROWTYPE;
    BEGIN
        IF in_log_id IS NULL THEN
            err.get_caller_info (  -- basically who called this
                out_module_name     => rec.module_name,
                out_module_line     => rec.module_line,
                out_module_depth    => rec.module_depth,
                out_parent_id       => rec.log_parent
            );
        END IF;
        --
        UPDATE logs e
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



    PROCEDURE update_message (
        in_log_id           logs.log_id%TYPE,
        in_message          logs.message%TYPE
    ) AS
    BEGIN
        err.log__ (
            in_action_name  => NULL,
            in_flag         => err.flag_query,
            in_arguments    => NULL,
            in_message      => in_message,
            in_parent_id    => in_log_id
        );
    END;



    FUNCTION get_dml_tracker
    RETURN VARCHAR2 AS
    BEGIN
        RETURN recent_log_id || ' ' || err.get_caller_name();
    END;



    PROCEDURE purge_old AS
        partition_date  VARCHAR2(10);   -- YYYY-MM-DD
        count_before    PLS_INTEGER;
        count_after     PLS_INTEGER;
    BEGIN
        err.log_module();

        -- delete old LOBs
        DELETE FROM logs_lobs
        WHERE lob_id IN (
            SELECT l.log_id
            FROM logs e
            JOIN logs_lobs l
                ON l.log_id = e.log_id
            WHERE e.created_at < TRUNC(SYSDATE) - err.table_rows_max_age
        );

        -- purge whole partitions
        FOR c IN (
            SELECT table_name, partition_name, high_value, partition_position
            FROM user_tab_partitions p
            WHERE p.table_name = err.table_name
                AND p.partition_position > 1
                AND p.partition_position < (
                    SELECT MAX(partition_position) - err.table_rows_max_age
                    FROM user_tab_partitions
                    WHERE table_name = err.table_name
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
            err.log_result(c.partition_name, partition_date, count_before, count_after);
        END LOOP;
    END;

BEGIN

    -- prepare collections when session starts
    -- load whitelist/blacklist data from logs_tracing table
    SELECT t.*
    BULK COLLECT INTO rows_whitelist
    FROM logs_tracking t
    WHERE t.track   = 'Y'
        AND ROWNUM  <= rows_limit;
    --
    SELECT t.*
    BULK COLLECT INTO rows_blacklist
    FROM logs_tracking t
    WHERE t.track   = 'N'
        AND ROWNUM  <= rows_limit;

END;
/

