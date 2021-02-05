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
    RETURN users.user_id%TYPE AS
    BEGIN
        RETURN sess.get_user_name(COALESCE(APEX_APPLICATION.G_USER, app_user_id, USER));
    END;



    FUNCTION get_user_name (
        in_username         sessions.user_id%TYPE
    )
    RETURN users.user_id%TYPE AS
    BEGIN
        RETURN LTRIM(RTRIM(
            CONVERT(
                CASE WHEN NVL(INSTR(in_username, '@'), 0) > 0
                    THEN LOWER(in_username)                     -- emails lowercased
                    ELSE UPPER(in_username) END,                -- otherwise uppercased
                'US7ASCII')                                     -- convert special chars
        ));
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



    FUNCTION get_page_group (
        in_page_id          sessions.page_id%TYPE       := NULL
    )
    RETURN apex_application_pages.page_group%TYPE
    AS
        out_name            apex_application_pages.page_group%TYPE;
    BEGIN
        SELECT p.page_group INTO out_name
        FROM apex_application_pages p
        WHERE p.application_id      = sess.get_app_id()
            AND p.page_id           = COALESCE(in_page_id, sess.get_page_id());
        --
        RETURN out_name;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_root_page_id (
        in_page_id          sessions.page_id%TYPE       := NULL
    )
    RETURN apex_application_pages.page_id%TYPE
    AS
        out_id              apex_application_pages.page_id%TYPE;
    BEGIN
        SELECT REGEXP_SUBSTR(MAX(SYS_CONNECT_BY_PATH(n.page_id, '/')), '[0-9]+$') INTO out_id
        FROM navigation n
        WHERE n.app_id          = sess.get_app_id()
        CONNECT BY n.app_id     = PRIOR n.app_id
            AND n.page_id       = PRIOR n.parent_id
        START WITH n.page_id    = COALESCE(in_page_id, sess.get_page_id());
        --
        RETURN out_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE AS
    BEGIN
        RETURN COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_SESSION'), 0);
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
    WHEN OTHERS THEN
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



    FUNCTION get_request
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN UTL_URL.UNESCAPE(
            OWA_UTIL.GET_CGI_ENV('SCRIPT_NAME') ||
            OWA_UTIL.GET_CGI_ENV('PATH_INFO')   || '?' ||
            OWA_UTIL.GET_CGI_ENV('QUERY_STRING')
        );
    EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
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
        --
        IF UPPER(in_user_id) = sess.anonymous_user THEN
            RETURN;
        END IF;

        -- load APEX items from recent (previous) session
        BEGIN
            apex.apply_items(sess.get_recent_items());
        EXCEPTION
        WHEN OTHERS THEN
            NULL;
        END;

        -- log request
        tree.log_module('START');

        -- insert or update sessions table
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
        sess.create_session (
            in_user_id => in_user_id
        );
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'CREATE_SESSION_FAILED', TRUE);
    END;



    PROCEDURE update_session (
        in_note             VARCHAR2                := NULL
    )
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        in_user_id          CONSTANT users.user_id%TYPE := sess.get_user_id();
        --
        rec                 sessions%ROWTYPE;
        req                 VARCHAR2(4000);
        --
        -- DONT CALL TREE PACKAGE FROM THIS MODULE
        --
    BEGIN
        IF UPPER(in_user_id) = sess.anonymous_user THEN
            RETURN;
        END IF;

        -- make sure user exists (after successful authentication)
        BEGIN
            SELECT u.user_id INTO rec.user_id
            FROM users u
            WHERE u.user_id = in_user_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            sess_create_user(in_user_id);
        END;

        -- values to store
        rec.session_id      := sess.get_session_id();
        rec.app_id          := sess.get_app_id();
        rec.page_id         := sess.get_page_id();
        rec.session_db      := sess.get_session_db();
        rec.updated_at      := SYSDATE;
        --
        IF rec.page_id BETWEEN sess.app_min_page AND sess.app_max_page THEN
            -- check for global items change requests
            req := SUBSTR(sess.get_request(), 1, 4000);
            FOR c IN (
                SELECT t.item_name, t.item_value
                FROM (
                    SELECT
                        REPLACE(REGEXP_SUBSTR(req, '[^&' || ']+[=]', 1, LEVEL), '=', '')                                            AS item_name,
                        REPLACE(REGEXP_SUBSTR(req, '[^&' || ']+',    1, LEVEL), REGEXP_SUBSTR(req, '[^&' || ']+[=]', 1, LEVEL), '') AS item_value
                    FROM DUAL
                    CONNECT BY LEVEL <= REGEXP_COUNT(req, '&' || 'G') + 1
                ) t
                JOIN apex_application_items a
                    ON a.application_id     = rec.app_id
                    AND a.item_name         = t.item_name
            ) LOOP
                apex.set_item(c.item_name, c.item_value);
            END LOOP;

            -- automatic items reset, co no need for reset page process
            IF REGEXP_LIKE(req, '[:,]' || 'P' || rec.page_id || '_RESET' || '[,:]') THEN  -- @TODO: should check also Y value
                apex.clear_items();
            END IF;

            -- app specific item manipulation
            sess_update_items();

            -- load items
            rec.apex_items  := apex.get_global_items();
        END IF;

        -- update record
        UPDATE sessions s
        SET s.page_id       = rec.page_id,
            s.apex_items    = COALESCE(rec.apex_items, s.apex_items),
            s.session_db    = rec.session_db,
            s.updated_at    = rec.updated_at
        WHERE s.session_id  = rec.session_id
            AND s.user_id   = rec.user_id
            AND s.app_id    = rec.app_id;       -- prevent app_id and user_id hijacking
        --
        IF SQL%ROWCOUNT = 0 THEN
            rec.created_at  := rec.updated_at;
            --
            BEGIN
                INSERT INTO sessions VALUES rec;
            EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;  -- redirect to logout/login page
            END;
        END IF;
        --
        COMMIT;

        -- log request, except for login page
        IF rec.page_id != 9999 THEN
            tree.log_module (
                in_note,
                APEX_APPLICATION.G_REQUEST,                                 -- button name
                REGEXP_REPLACE(req, '^/[^/]+/[^/]+/f[?]p=([^:]*:){6}', '')  -- arguments in URL
            );
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(tree.app_exception_code, 'UPDATE_SESSION_FAILED', TRUE);
    END;



    PROCEDURE delete_session (
        in_session_id       sessions.session_id%TYPE,
        in_created_at       sessions.created_at%TYPE
    ) AS
        keep_this           logs.log_id%TYPE;
        rows_to_delete      tree.arr_logs_log_id;
    BEGIN
        keep_this := tree.log_module();
        --
        SELECT l.log_id
        BULK COLLECT INTO rows_to_delete
        FROM logs l
        WHERE l.session_id      = in_session_id
            AND l.log_parent    IS NULL
            AND l.created_at    >= TRUNC(in_created_at);
        --
        IF rows_to_delete.FIRST IS NOT NULL THEN
            FOR i IN rows_to_delete.FIRST .. rows_to_delete.LAST LOOP
                IF keep_this != rows_to_delete(i) THEN
                    tree.delete_tree(rows_to_delete(i));
                    COMMIT;
                END IF;
            END LOOP;
        END IF;
        --
        DELETE FROM sessions s
        WHERE s.session_id      = in_session_id
            AND s.session_id    != sess.get_session_id();
        --
        tree.update_timer();
    END;



    FUNCTION get_recent_items (
        in_user_id          sessions.user_id%TYPE       := NULL,
        in_app_id           sessions.app_id%TYPE        := NULL
    )
    RETURN sessions.apex_items%TYPE AS
        out_payload         sessions.apex_items%TYPE;
    BEGIN
        SELECT s.apex_items INTO out_payload
        FROM sessions s
        WHERE s.session_id = (
            SELECT MAX(s.session_id)        -- @TODO: MIN(d.id) KEEP (DENSE_RANK FIRST ORDER BY d.id)
            FROM sessions s
            WHERE s.user_id         = COALESCE(in_user_id, sess.get_user_id())
                AND s.app_id        = COALESCE(in_app_id,  sess.get_app_id(), s.app_id)
                AND s.session_id    != sess.get_session_id()
        );
        --
        RETURN out_payload;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
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

END;
/
