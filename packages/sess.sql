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

        -- log request
        tree.log_module('START');

        -- load APEX items from recent (previous) session
        BEGIN
            apex.apply_items(sess.get_recent_items());
        EXCEPTION
        WHEN OTHERS THEN
            NULL;
        END;

        --
        BEGIN
            INSERT INTO calendar (app_id, today, today__)
            VALUES (
                sess.get_app_id(),
                TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
                TRUNC(SYSDATE)
            );
        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;

        -- insert or update sessions table
        sess.update_session();
        --
        COMMIT;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        --
        tree.raise_error('CREATE_SESSION_FAILED');
    END;



    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := 0
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        is_active           CHAR(1);
    BEGIN
        sess.init_session(in_user_id);

        -- check app existance
        BEGIN
            SELECT 'Y' INTO is_active
            FROM apps a
            WHERE a.app_id = in_app_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'APPLICATION_MISSING');
        END;

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
    WHEN tree.app_exception THEN
        RAISE;
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        COMMIT;
    WHEN OTHERS THEN
        ROLLBACK;
        --
        tree.raise_error('CREATE_SESSION_FAILED');
    END;



    PROCEDURE update_session (
        in_note             VARCHAR2                := NULL
    )
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        in_user_id          CONSTANT users.user_id%TYPE := sess.get_user_id();
        is_developer        CONSTANT CHAR(1)            := CASE WHEN apex.is_developer() THEN 'Y' END;
        --
        is_active           CHAR(1);
        rec                 sessions%ROWTYPE;
        req                 VARCHAR2(4000);
        --
        -- DONT CALL TREE PACKAGE FROM THIS MODULE
        --
    BEGIN
        IF UPPER(in_user_id) = sess.anonymous_user THEN
            RETURN;
        END IF;

        -- check app availability
        BEGIN
            SELECT 'Y' INTO is_active
            FROM apps a
            WHERE a.app_id          = sess.get_app_id()
                AND (a.is_active    = 'Y' OR is_developer = 'Y');
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(tree.app_exception_code, 'APPLICATION_OFFLINE');
        END;

        -- make sure user exists (after successful authentication)
        BEGIN
            SELECT u.user_id, u.is_active
            INTO rec.user_id, is_active
            FROM users u
            WHERE u.user_id = in_user_id;
            --
            IF is_active IS NULL THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'ACCOUNT_DISABLED');
            END IF;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                sess_create_user(in_user_id);
                --
                rec.user_id := in_user_id;
            EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'CREATE_USER_FAILED', TRUE);
            END;
        END;

        -- values to store
        rec.session_id      := sess.get_session_id();
        rec.app_id          := sess.get_app_id();
        rec.page_id         := sess.get_page_id();
        rec.session_db      := sess.get_session_db();
        rec.updated_at      := SYSDATE;
        rec.today           := TO_CHAR(rec.updated_at, 'YYYY-MM-DD');
        --
        IF rec.page_id BETWEEN sess.app_min_page AND sess.app_max_page THEN
            -- automatic items reset, co no need for reset page process
            req := SUBSTR(sess.get_request(), 1, 4000);
            --
            IF REGEXP_LIKE(req, '[:,]' || 'P' || rec.page_id || '_RESET' || '[,:]') THEN  -- @TODO: should check also Y value
                apex.clear_items();
            ELSIF req LIKE '%p' || rec.page_id || '_reset=Y%' THEN  -- for friendly url
                apex.clear_items();
            END IF;

            -- app specific item manipulation
            sess_update_items();

            -- load items
            rec.apex_items  := apex.get_global_items();
        END IF;

        -- update record, prevent app_id and user_id hijacking
        UPDATE sessions s
        SET s.page_id       = rec.page_id,
            s.apex_items    = COALESCE(rec.apex_items, s.apex_items),
            s.session_db    = rec.session_db,
            s.updated_at    = rec.updated_at
        WHERE s.session_id  = rec.session_id
            AND s.user_id   = rec.user_id
            AND s.app_id    = rec.app_id
        RETURNING s.created_at INTO rec.created_at;
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
        ELSIF TRUNC(rec.created_at) < TRUNC(rec.updated_at) THEN    -- avoid sessions thru multiple days
            sess.force_new_session();
        END IF;

        -- log request, except for login page
        IF rec.page_id != 9999 THEN
            rec.log_id := tree.log_module (
                in_note,
                APEX_APPLICATION.G_REQUEST,                                 -- button name
                REGEXP_REPLACE(req, '^/[^/]+/[^/]+/f[?]p=([^:]*:){6}', '')  -- arguments in URL
            );

            -- store log_id to use it as parent for all further requests
            UPDATE sessions s
            SET s.log_id        = rec.log_id
            WHERE s.session_id  = rec.session_id;
            --
            tree.curr_page_log_id   := rec.log_id;
            tree.curr_page_stamp    := SYSTIMESTAMP;
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        COMMIT;
    WHEN OTHERS THEN
        ROLLBACK;
        --
        tree.raise_error('UPDATE_SESSION_FAILED');
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
            AND l.created_at    >= TRUNC(in_created_at)
        CONNECT BY l.log_parent = PRIOR l.log_id
        START WITH l.log_id     = tree.get_tree_id();
        --
        IF rows_to_delete.FIRST IS NOT NULL THEN
            FOR i IN rows_to_delete.FIRST .. rows_to_delete.LAST LOOP
                IF keep_this != rows_to_delete(i) THEN
                    DELETE FROM logs_lobs   WHERE log_parent    = rows_to_delete(i);
                    DELETE FROM logs        WHERE log_id        = rows_to_delete(i);
                END IF;
            END LOOP;
        END IF;
        --
        IF in_session_id != sess.get_session_id() THEN
            DELETE FROM sessions s
            WHERE s.session_id = in_session_id;
            --
            APEX_SESSION.DELETE_SESSION(in_session_id);
        END IF;
        --
        tree.update_timer();
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        --
        tree.raise_error('DELETE_SESSION_FAILED');
    END;



    PROCEDURE force_new_session AS
    BEGIN
        FOR c IN (
            SELECT s.session_id
            FROM sessions s
            WHERE s.app_id          = sess.get_app_id()
                AND s.session_id    = sess.get_session_id()
        ) LOOP
            tree.log_module();
            --
            COMMIT;
            APEX_UTIL.REDIRECT_URL(APEX_PAGE.GET_URL(p_session => 0));  -- force new login
        END LOOP;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        NULL;
    WHEN OTHERS THEN
        tree.raise_error('FORCE_NEW_SESSION_FAILED');
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



    FUNCTION get_time_bucket (
        in_date             DATE,
        in_interval         NUMBER
    )
    RETURN NUMBER
    RESULT_CACHE
    AS
        out_group_id        NUMBER;
    BEGIN
        WITH x AS (
            SELECT
                LEVEL AS group_id,
                CAST(TRUNC(in_date) + NUMTODSINTERVAL((LEVEL - 1) * in_interval, 'MINUTE') AS DATE) AS start_at,
                CAST(TRUNC(in_date) + NUMTODSINTERVAL( LEVEL      * in_interval, 'MINUTE') AS DATE) AS end_at
            FROM DUAL
            CONNECT BY LEVEL <= (1440 / in_interval)
        )
        SELECT x.group_id INTO out_group_id
        FROM x
        WHERE in_date       >= x.start_at
            AND in_date     <  x.end_at;
        --
        RETURN out_group_id;
    END;

END;
/
