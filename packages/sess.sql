CREATE OR REPLACE PACKAGE BODY sess AS

    recent_session_db       sessions.session_db%TYPE;       -- to save resources
    --
    app_user_id             sessions.user_id%TYPE;          -- user_id used when called outside of APEX



    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE AS
    BEGIN
        RETURN COALESCE(APEX_APPLICATION.G_FLOW_ID, 0);
    END;



    FUNCTION get_user_id
    RETURN sessions.user_id%TYPE AS
    BEGIN
        RETURN COALESCE(COALESCE(APEX_APPLICATION.G_USER, app_user_id), USER);
    END;



    FUNCTION get_user_lang
    RETURN users.lang%TYPE AS
        out_lang users.lang%TYPE;
    BEGIN
        SELECT u.lang INTO out_lang
        FROM users u
        WHERE u.user_id = sess.get_user_id;
        --
        RETURN out_lang;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_page_id
    RETURN sessions.page_id%TYPE AS
    BEGIN
        RETURN NVL(APEX_APPLICATION.G_FLOW_STEP_ID, 0);
    END;



    FUNCTION get_page_group
    RETURN apex_application_pages.page_group%TYPE
    AS
        out_name apex_application_pages.page_group%TYPE;
    BEGIN
        SELECT p.page_group INTO out_name
        FROM apex_application_pages p
        WHERE p.application_id = sess.get_app_id();
        --
        RETURN out_name;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE AS
    BEGIN
        RETURN NVL(SYS_CONTEXT('APEX$SESSION', 'APP_SESSION'), 0);
    END;



    FUNCTION get_session_db
    RETURN sessions.session_db%TYPE AS
    BEGIN
        --
        -- @TODO: explore DBMS_SESSION.UNIQUE_SESSION_ID
        --
        IF recent_session_db IS NULL THEN
            SELECT TO_NUMBER(s.sid || '.' || s.serial#, '9999D999999', 'NLS_NUMERIC_CHARACTERS=''. ''')
            INTO recent_session_db
            FROM v$session s
            WHERE s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
        END IF;
        --
        RETURN NVL(recent_session_db, 0);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    END;



    FUNCTION get_client_id (
        in_user_id          sessions.user_id%TYPE := NULL
    )
    RETURN VARCHAR2 AS      -- mimic APEX client_id
    BEGIN
        RETURN
            COALESCE(in_user_id, sess.get_user_id()) || ':' ||
            COALESCE(sess.get_session_id(), SYS_CONTEXT('USERENV', 'SESSIONID'));
    END;



    PROCEDURE init_session AS
    BEGIN
        DBMS_SESSION.CLEAR_IDENTIFIER();
        --
        DBMS_APPLICATION_INFO.SET_MODULE (
            module_name => NULL,
            action_name => NULL
        );
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
        app_user_id := in_user_id;
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec sessions%ROWTYPE;
    BEGIN
        sess.init_session(in_user_id);
        sess.update_session();
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'CREATE_SESSION_FAILED', TRUE);
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := 0
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        sess.init_session(in_user_id);

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
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'CREATE_SESSION_FAILED', TRUE);
    END;



    PROCEDURE update_session
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 sessions%ROWTYPE;
        --
        -- DONT CALL TREE PACKAGE FROM THIS MODULE
        --
    BEGIN
        rec.session_id      := sess.get_session_id();
        rec.page_id         := sess.get_page_id();
        rec.updated_at      := SYSTIMESTAMP;
        --
        IF rec.page_id BETWEEN sess.app_min_page AND sess.app_max_page THEN
            rec.apex_items  := sess.get_apex_items();
        END IF;
        --
        UPDATE sessions s
        SET s.page_id       = rec.page_id,
            s.apex_items    = rec.apex_items,
            s.updated_at    = rec.updated_at
        WHERE s.session_id  = rec.session_id;
        --
        IF SQL%ROWCOUNT = 0 THEN
            rec.app_id          := sess.get_app_id();
            rec.user_id         := sess.get_user_id();
            rec.session_db      := sess.get_session_db();
            rec.created_at      := rec.created_at;
            --
            INSERT INTO sessions VALUES rec;
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'UPDATE_SESSION_FAILED', TRUE);
    END;



    FUNCTION get_role_status (
        in_role_id          user_roles.role_id%TYPE,
        in_user_id          user_roles.user_id%TYPE     := NULL,
        in_app_id           user_roles.app_id%TYPE      := NULL
    )
    RETURN BOOLEAN AS
        role_exists         PLS_INTEGER;
    BEGIN
        SELECT 1 INTO role_exists
        FROM user_roles r
        WHERE r.app_id      = COALESCE(in_app_id,  sess.get_app_id())
            AND r.user_id   = COALESCE(in_user_id, sess.get_user_id())
            AND r.role_id   = in_role_id;
        --
        RETURN TRUE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;



    FUNCTION get_apex_items
    RETURN sessions.apex_items%TYPE
    AS
        out_items       sessions.apex_items%TYPE;
    BEGIN
        --
        -- @TODO: return as JSON object
        --
        /*
        SELECT
            LISTAGG(t.item_name || sess.splitter_values || APEX_UTIL.GET_SESSION_STATE(t.item_name), sess.splitter_rows)
                WITHIN GROUP (ORDER BY t.item_name)
        INTO out_items
        FROM apex_application_items t
        WHERE t.application_id = sess.get_app_id()
            AND APEX_UTIL.GET_SESSION_STATE(t.item_name) IS NOT NULL;
        --
        /*
        -- APPEND^
        SELECT
            LISTAGG(t.item_name || sess.splitter_values || APEX_UTIL.GET_SESSION_STATE(t.item_name), sess.splitter_rows)
                WITHIN GROUP (ORDER BY t.item_name)
        INTO out_items
        FROM apex_application_page_items t
        WHERE t.application_id  = sess.get_app_id()
            AND t.page_id       = sess.get_page_id()
            AND APEX_UTIL.GET_SESSION_STATE(t.item_name) IS NOT NULL;
        */
        --
        RETURN out_items;
    END;

END;
/
