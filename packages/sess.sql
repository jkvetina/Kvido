CREATE OR REPLACE PACKAGE BODY sess AS

    recent_session_db       sessions.session_db%TYPE;      -- to save resources
    recent_session_id       sessions.session_id%TYPE;



    PROCEDURE init_session AS
    BEGIN
        DBMS_SESSION.CLEAR_ALL_CONTEXT(sess.app_namespace);
        DBMS_SESSION.CLEAR_IDENTIFIER();
        --
        DBMS_APPLICATION_INFO.SET_MODULE (
            module_name => NULL,
            action_name => NULL
        );
        --
        recent_session_id := NULL;
    END;



    PROCEDURE init_session (
        in_user_id          sessions.user_id%TYPE
    ) AS
    BEGIN
        sess.init_session();

        -- set session things
        DBMS_SESSION.SET_IDENTIFIER(in_user_id);                -- USERENV.CLIENT_IDENTIFIER
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(in_user_id);      -- CLIENT_INFO, v$
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace   => sess.app_namespace,
            attribute   => sess.app_user_attr,
            value       => in_user_id,
            username    => in_user_id,
            client_id   => sess.get_client_id(in_user_id)
        );
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_message          logs.message%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        sess.init_session(in_user_id);

        -- load previous session
        sess.load_session (
            in_user_id          => in_user_id,
            in_app_id           => sess.get_app_id(),
            in_page_id          => sess.get_page_id(),
            in_session_db       => sess.get_session_db(),
            in_session_apex     => sess.get_session_apex(),
            in_created_at_min   => NULL
        );

        -- store new values
        sess.update_session();
        --
        tree.log_module(in_user_id, in_message);
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_SESSION_FAILED', TRUE);
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_contexts         sessions.contexts%TYPE,
        in_message          logs.message%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        sess.init_session(in_user_id);

        -- load resp. apply passed contexts
        IF in_contexts IS NOT NULL THEN
            sess.apply_contexts(in_contexts);
        END IF;

        -- store new values
        sess.update_session();
        --
        tree.log_module(in_user_id, LENGTH(in_contexts), in_message);
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_SESSION_FAILED', TRUE);
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.user_id%TYPE,
        in_message          logs.message%TYPE           := NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        sess.init_session(in_user_id);

        $IF $$APEX_INSTALLED $THEN
            -- find and setup workspace
            FOR a IN (
                SELECT a.workspace
                FROM apex_applications a
                WHERE a.application_id  = in_app_id
                    AND ROWNUM          = 1
            ) LOOP
                APEX_UTIL.SET_WORKSPACE (
                    p_workspace => a.workspace
                );
                APEX_UTIL.SET_SECURITY_GROUP_ID (
                    p_security_group_id => APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => a.workspace)
                );
                APEX_UTIL.SET_USERNAME (
                    p_userid    => APEX_UTIL.GET_USER_ID(in_user_id),
                    p_username  => in_user_id
                );
            END LOOP;

            -- create APEX session
            APEX_SESSION.CREATE_SESSION (
                p_app_id    => in_app_id,
                p_page_id   => in_page_id,
                p_username  => in_user_id
            );
        $END

        -- load previous session
        sess.load_session (
            in_user_id          => in_user_id,
            in_app_id           => in_app_id,
            in_page_id          => in_page_id,
            in_session_db       => NULL,
            in_session_apex     => NULL,
            in_created_at_min   => NULL
        );

        -- store new values
        sess.update_session();
        --
        tree.log_module(in_user_id, in_app_id, in_page_id, in_message);
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_SESSION_FAILED', TRUE);
    END;



    PROCEDURE load_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := NULL,
        in_session_db       sessions.session_db%TYPE    := NULL,
        in_session_apex     sessions.session_apex%TYPE  := NULL,
        in_created_at_min   sessions.created_at%TYPE    := NULL
    ) AS
        rec                 sessions%ROWTYPE;
    BEGIN
        tree.log_module(in_user_id, in_app_id, in_page_id, in_session_db, in_session_apex, in_created_at_min);

        -- find best session
        SELECT s.* INTO rec
        FROM sessions s
        WHERE s.session_id = (
            SELECT MIN(s.session_id) KEEP (DENSE_RANK FIRST
                ORDER BY
                    CASE s.session_apex WHEN in_session_apex    THEN 1 END NULLS LAST,
                    CASE s.session_db   WHEN in_session_db      THEN 1 END NULLS LAST,
                    CASE s.page_id      WHEN in_page_id         THEN 1 END NULLS LAST,
                    s.session_id DESC
                )
            FROM sessions s
            WHERE s.user_id         = NVL(in_user_id,           sess.get_user_id())
                AND s.app_id        = NVL(in_app_id,            sess.get_app_id())
                AND s.page_id       = NVL(in_page_id,           s.page_id)
                AND s.session_db    = NVL(in_session_db,        s.session_db)
                AND s.session_apex  = NVL(in_session_apex,      s.session_apex)
                AND s.created_at    >= NVL(in_created_at_min,   TRUNC(SYSDATE))
        );

        -- prepare contexts
        IF rec.contexts IS NOT NULL THEN
            sess.apply_contexts(rec.contexts);
        END IF;

        -- prepare APEX items
        $IF $$APEX_INSTALLED $THEN
            IF COALESCE(in_page_id, rec.apex_globals) IS NOT NULL THEN
                sess.apply_items(rec.apex_globals);
            END IF;
            --
            IF COALESCE(in_page_id, rec.apex_locals) IS NOT NULL THEN
                sess.apply_items(rec.apex_locals);
            END IF;
        $END
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'LOAD_SESSION_NOT_FOUND', TRUE);
    END;



    PROCEDURE update_session
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 sessions%ROWTYPE;
        --
        -- DONT CALL BUG PACKAGE FROM THIS MODULE
        --
    BEGIN
        rec.session_id      := session_id.NEXTVAL;
        recent_session_id   := rec.session_id;
        --
        rec.user_id         := sess.get_user_id();
        rec.app_id          := NVL(sess.get_app_id(),        0);
        rec.page_id         := NVL(sess.get_page_id(),       0);
        rec.session_db      := NVL(sess.get_session_db(),    0);
        rec.session_apex    := NVL(sess.get_session_apex(),  0);
        rec.contexts        := sess.get_contexts();
        rec.created_at      := SYSTIMESTAMP;
        --
        IF rec.page_id > 0 THEN
            rec.apex_globals    := sess.get_apex_globals();
            rec.apex_locals     := sess.get_apex_locals();
        END IF;

        -- store new values
        INSERT INTO sessions VALUES rec;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SAVE_SESSION_FAILED', TRUE);
    END;



    PROCEDURE update_session (
        in_log_id           logs.log_id%TYPE
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        sess.update_session();
        --
        UPDATE logs e
        SET e.session_id    = recent_session_id
        WHERE e.log_id      = in_log_id;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SAVE_SESSION_FAILED', TRUE);
    END;



    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE AS
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            RETURN NVL(APEX_APPLICATION.G_FLOW_ID, 0);
        $ELSE
            RETURN 0;
        $END    
    END;



    FUNCTION get_page_id
    RETURN sessions.page_id%TYPE AS
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            RETURN APEX_APPLICATION.G_FLOW_STEP_ID;
        $ELSE
            RETURN NULL;
        $END    
    END;



    FUNCTION get_user_id
    RETURN sessions.user_id%TYPE AS
    BEGIN
        RETURN NVL(NULLIF(
            COALESCE (                                              -- APEX first, because it is more reliable
                SYS_CONTEXT('APEX$SESSION', 'APP_USER'),            -- APEX_APPLICATION.G_USER
                SYS_CONTEXT(sess.app_namespace, sess.app_user_attr),
                sess.app_user
            ),
            tree.dml_tables_owner), tree.empty_user);        
    END;



    FUNCTION get_session_db
    RETURN sessions.session_db%TYPE AS
    BEGIN
        IF recent_session_db IS NULL THEN
            SELECT TO_NUMBER(s.sid || '.' || s.serial#) INTO recent_session_db
            FROM v$session s
            WHERE s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
        END IF;
        --
        RETURN recent_session_db;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_session_apex
    RETURN sessions.session_apex%TYPE AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
    END;



    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE AS
    BEGIN
        RETURN recent_session_id;
    END;



    FUNCTION get_client_id (
        in_user_id          sessions.user_id%TYPE := NULL
    )
    RETURN VARCHAR2 AS      -- mimic APEX client_id
    BEGIN
        RETURN
            NVL(in_user_id, sess.get_user_id()) || ':' ||
            NVL(sess.get_session_apex(), SYS_CONTEXT('USERENV', 'SESSIONID'));
    END;



    FUNCTION get_context (
        in_name     VARCHAR2,
        in_format   VARCHAR2    := NULL,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN VARCHAR2 AS
    BEGIN
        IF in_format IS NOT NULL THEN
            RETURN TO_CHAR(sess.get_context_date(UPPER(in_name)), in_format);
        END IF;
        --
        RETURN SYS_CONTEXT(sess.app_namespace, UPPER(in_name));
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
        END IF;
        --
        RETURN NULL;
    END;



    FUNCTION get_context_number (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN NUMBER AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT(sess.app_namespace, UPPER(in_name)));
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
        END IF;
        --
        RETURN NULL;
    END;



    FUNCTION get_context_date (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN DATE AS
    BEGIN
        RETURN TO_DATE(SYS_CONTEXT(sess.app_namespace, UPPER(in_name)), sess.format_date_time);
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
        END IF;
        --
        RETURN NULL;
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    VARCHAR2        := NULL
    ) AS
    BEGIN
        IF SYS_CONTEXT(sess.app_namespace, sess.app_user_attr) IS NULL THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_CTX_USER_ID', TRUE);
        END IF;
        --
        IF in_name LIKE '%\_\_' ESCAPE '\' OR in_name IS NULL THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_CTX_FORBIDDEN', TRUE);
        END IF;
        --
        IF in_value IS NULL THEN
            DBMS_SESSION.CLEAR_CONTEXT (
                namespace           => sess.app_namespace,
                --client_identifier   => sess.get_client_id(),
                attribute           => UPPER(in_name)
            );
            RETURN;
        END IF;
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace    => sess.app_namespace,
            attribute    => UPPER(in_name),
            value        => in_value,
            username     => sess.get_user_id(),
            client_id    => sess.get_client_id()
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_CTX_FAILED', TRUE);
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    DATE
    ) AS
        str_value   VARCHAR2(30);
    BEGIN
        IF SYS_CONTEXT(sess.app_namespace, sess.app_user_attr) IS NULL THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_CTX_DATE_USER_ID', TRUE);
        END IF;
        --
        str_value := TO_CHAR(in_value, sess.format_date_time);
        --
        sess.set_context (
            in_name     => in_name,
            in_value    => str_value
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'SET_CTX_DATE_FAILED', TRUE);
    END;



    PROCEDURE apply_contexts (
        in_contexts         sessions.contexts%TYPE,
        in_append           BOOLEAN                     := FALSE
    ) AS
        payload_item        sessions.contexts%TYPE;
        payload_name        sessions.contexts%TYPE;
        payload_value       sessions.contexts%TYPE;
    BEGIN
        IF NOT in_append THEN
            -- clear contexts
            FOR c IN (
                SELECT s.attribute
                FROM session_context s
                WHERE s.namespace       = sess.app_namespace
                    AND s.attribute     != sess.app_user_attr            -- user_id has dedicated column
                    AND s.value         IS NOT NULL
            ) LOOP
                sess.set_context (
                    in_name     => c.attribute
                );
            END LOOP;
        END IF;
        --
        IF in_contexts IS NULL THEN
            RETURN;
        END IF;
        --
        FOR i IN 1 .. REGEXP_COUNT(in_contexts, '[' || sess.splitter_rows || ']') + 1 LOOP
            payload_item    := REGEXP_SUBSTR(in_contexts, '[^' || sess.splitter_rows || ']+', 1, i);
            payload_name    := RTRIM(SUBSTR(payload_item, 1, INSTR(payload_item, sess.splitter_values) - 1));
            payload_value   := SUBSTR(payload_item, INSTR(payload_item, sess.splitter_values) + 1);
            --
            IF payload_name IS NOT NULL THEN
                sess.set_context (
                    in_name     => payload_name,
                    in_value    => payload_value
                );
            END IF;
        END LOOP;
    END;



    PROCEDURE apply_items (
        in_items            sessions.apex_locals%TYPE
    ) AS
        payload_item        sessions.contexts%TYPE;
        payload_name        sessions.contexts%TYPE;
        payload_value       sessions.contexts%TYPE;
    BEGIN
        IF in_items IS NULL THEN
            RETURN;
        END IF;
        --
        $IF $$APEX_INSTALLED $THEN
            FOR i IN 1 .. REGEXP_COUNT(in_items, '[' || sess.splitter_rows || ']') + 1 LOOP
                payload_item    := REGEXP_SUBSTR(in_items, '[^' || sess.splitter_rows || ']+', 1, i);
                payload_name    := RTRIM(SUBSTR(payload_item, 1, INSTR(payload_item, sess.splitter_values) - 1));
                payload_value   := SUBSTR(payload_item, INSTR(payload_item, sess.splitter_values) + 1);
                --
                IF payload_name IS NOT NULL AND payload_value IS NOT NULL THEN
                    APEX_UTIL.SET_SESSION_STATE(payload_name, payload_value);
                END IF;
            END LOOP;
        $END    
    END;



    FUNCTION get_contexts
    RETURN sessions.contexts%TYPE
    AS
        out_payload     sessions.contexts%TYPE;
    BEGIN
        SELECT
            LISTAGG(s.attribute || sess.splitter_values || s.value, sess.splitter_rows)
                WITHIN GROUP (ORDER BY s.attribute)
        INTO out_payload
        FROM session_context s
        WHERE s.namespace       = sess.app_namespace
            AND s.attribute     != sess.app_user_attr            -- user_id has dedicated column
            AND s.attribute     NOT LIKE '%\_\_' ESCAPE '\'     -- ignore private contexts
            AND s.value         IS NOT NULL;
        --
        RETURN out_payload;
    END;



    FUNCTION get_apex_globals
    RETURN sessions.apex_globals%TYPE
    AS
        out_items       sessions.apex_globals%TYPE;
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            SELECT
                LISTAGG(t.item_name || sess.splitter_values || APEX_UTIL.GET_SESSION_STATE(t.item_name), sess.splitter_rows)
                    WITHIN GROUP (ORDER BY s.attribute)
            INTO out_items
            FROM apex_application_items t
            WHERE t.application_id = sess.get_app_id();
        $END    
        --
        RETURN out_items;
    END;



    FUNCTION get_apex_locals
    RETURN sessions.apex_locals%TYPE
    AS
        out_items       sessions.apex_locals%TYPE;
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            SELECT
                LISTAGG(t.item_name || sess.splitter_values || APEX_UTIL.GET_SESSION_STATE(t.item_name), sess.splitter_rows)
                    WITHIN GROUP (ORDER BY s.attribute)
            INTO out_items
            FROM apex_application_page_items t
            WHERE t.application_id  = sess.get_app_id()
                AND t.page_id       = sess.get_page_id();
        $END    
        --
        RETURN out_items;
    END;

END;
/
