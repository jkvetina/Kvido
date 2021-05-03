CREATE OR REPLACE PACKAGE BODY sess AS




    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE AS
    BEGIN
        RETURN COALESCE(APEX_APPLICATION.G_FLOW_ID, 0);
    END;



    FUNCTION get_user_id
    RETURN users.user_id%TYPE AS
    BEGIN
        RETURN COALESCE (
            APEX_APPLICATION.G_USER,
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            USER
        );
    END;



    FUNCTION get_user_id (
        in_user_login       users.user_login%TYPE
    )
    RETURN users.user_id%TYPE AS
    BEGIN
        -- shorten user_login to user_id
        RETURN REGEXP_REPLACE(LTRIM(RTRIM(
            CONVERT(
                CASE WHEN NVL(INSTR(in_user_login, '@'), 0) > 0
                    THEN LOWER(in_user_login)                       -- emails lowercased
                    ELSE UPPER(in_user_login) END,                  -- otherwise uppercased
                'US7ASCII')                                         -- convert special chars
        )), '@.*', '');
    END;



    PROCEDURE set_user_id AS
    BEGIN
        -- overwrite current user in APEX
        APEX_CUSTOM_AUTH.SET_USER (
            p_user => sess.get_user_id(sess.get_user_id())
        );
    END;



    FUNCTION get_user_name (
        in_user_id          sessions.user_id%TYPE       := NULL
    )
    RETURN users.user_name%TYPE
    AS
        out_name            users.user_name%TYPE;
    BEGIN
        SELECT u.user_name INTO out_name
        FROM users u
        WHERE u.user_id = in_user_id;
        --
        RETURN out_name;
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
    RETURN NUMBER AS
        out_ NUMBER;
    BEGIN
        --
        -- @TODO: explore DBMS_SESSION.UNIQUE_SESSION_ID
        --
        SELECT TO_NUMBER(s.sid || '.' || s.serial#, '9999D999999', 'NLS_NUMERIC_CHARACTERS=''. ''')
        INTO out_
        FROM v$session s
        WHERE s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
        --
        RETURN NVL(out_, 0);
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
    END;



    PROCEDURE clear_session (
        in_log_id       logs.log_id%TYPE        := NULL
    ) AS
        curr_log_id     logs.log_id%TYPE;
    BEGIN
        -- update timer for log_id stored at page start (before header)
        IF in_log_id IS NOT NULL THEN
            BEGIN
                SELECT s.log_id INTO curr_log_id
                FROM sessions s
                WHERE s.session_id = sess.get_session_id();
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            END;
        END IF;
        --
        tree.update_timer(NVL(curr_log_id, in_log_id));
        --
        DBMS_SESSION.CLEAR_IDENTIFIER();
        --DBMS_SESSION.CLEAR_ALL_CONTEXT(namespace);
        --DBMS_SESSION.RESET_PACKAGE;  -- avoid ORA-04068 exception
    END;



    PROCEDURE create_session AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        v_user_id               users.user_id%TYPE;
        v_is_active             users.is_active%TYPE;
    BEGIN
        -- this procedure is starting point in APEX after successful authentication
        -- prevent sessions for anonymous (unlogged) users
        IF UPPER(sess.get_user_id()) = sess.anonymous_user OR sess.get_app_id() = 0 THEN
            RETURN;
        END IF;

        -- make sure user exists
        BEGIN
            SELECT u.user_id, u.is_active INTO v_user_id, v_is_active
            FROM users u
            WHERE u.user_login = sess.get_user_id();
            --
            IF v_is_active IS NULL THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'ACCOUNT_DISABLED');
            END IF;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_user_id := sess.get_user_id();  -- it contains login just after auth
            --
            BEGIN
                -- create user account
                sess_create_user (
                    in_user_login       => v_user_id,
                    in_user_id          => sess.get_user_id(v_user_id),
                    in_user_name        => v_user_id
                );
                --
                v_user_id := sess.get_user_id(v_user_id);  -- overwrite with real user_id
            EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'CREATE_USER_FAILED', TRUE);
            END;
        END;

        -- adjust user_id in APEX, init session
        sess.set_user_id();
        sess.init_session(v_user_id);
        tree.log_module();

        -- load APEX items from recent (previous) session
        BEGIN
            apex.apply_items(sess.get_recent_items());
        EXCEPTION
        WHEN OTHERS THEN
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
        -- create session from SQL Developer (not from APEX)
        BEGIN
            IF (in_user_id != sess.get_user_id() OR in_app_id != sess.get_app_id()) THEN
                RAISE NO_DATA_FOUND;
            END IF;

            -- use existing session if possible
            APEX_SESSION.ATTACH (
                p_app_id        => sess.get_app_id(),
                p_page_id       => in_page_id,
                p_session_id    => sess.get_session_id()
            );
        EXCEPTION
        WHEN OTHERS THEN
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

                -- create APEX session
                BEGIN
                    APEX_SESSION.CREATE_SESSION (
                        p_app_id    => in_app_id,
                        p_page_id   => in_page_id,
                        p_username  => in_user_id
                    );
                EXCEPTION
                WHEN OTHERS THEN
                    tree.raise_error('INVALID_APP_OR_PAGE', in_app_id, in_page_id, in_user_id);
                END;
            END LOOP;
        END;

        -- go thru standard process as from APEX
        sess.create_session();
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



    PROCEDURE update_session
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        in_user_id          CONSTANT users.user_id%TYPE := sess.get_user_id();
        --
        is_active           apps.is_active%TYPE;
        rec                 sessions%ROWTYPE;
        req                 VARCHAR2(4000);
        --
        -- DONT CALL TREE PACKAGE FROM THIS MODULE
        --
    BEGIN
        -- prevent processing for anonymous users
        IF UPPER(in_user_id) = sess.anonymous_user THEN
            RETURN;
        END IF;

        -- check app availability
        IF NOT apex.is_developer() THEN
            BEGIN
                SELECT 'Y' INTO is_active
                FROM apps a
                WHERE a.app_id          = sess.get_app_id()
                    AND a.is_active     = 'Y';
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'APPLICATION_OFFLINE');
            END;
            --
            BEGIN
                SELECT 'Y' INTO is_active
                FROM user_roles r
                WHERE r.app_id          = sess.get_app_id()
                    AND r.user_id       = in_user_id
                    AND r.is_active     = 'Y'
                GROUP BY r.user_id
                HAVING COUNT(*) > 0;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(tree.app_exception_code, 'USER_TEMPORARLY_DISABLED');
            END;
        END IF;

        -- values to store
        rec.user_id         := in_user_id;
        rec.session_id      := sess.get_session_id();
        rec.app_id          := sess.get_app_id();
        rec.page_id         := sess.get_page_id();
        rec.updated_at      := SYSDATE;
        rec.created_at      := rec.updated_at;
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
            s.updated_at    = rec.updated_at
        WHERE s.session_id  = rec.session_id
            AND s.app_id    = rec.app_id
            AND s.user_id   = rec.user_id
        RETURNING s.created_at INTO rec.created_at;
        --
        IF SQL%ROWCOUNT = 0 THEN
            BEGIN
                INSERT INTO sessions VALUES rec;
            EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                -- redirect to logout/login page
                RAISE;
            END;
        ELSIF TRUNC(rec.created_at) < TRUNC(rec.updated_at) THEN
            -- avoid sessions thru multiple days
            sess.force_new_session();
        END IF;

        -- log request, except for login page
        IF rec.page_id != sess.login_page# THEN
            apex_log_id := tree.log_module (
                REGEXP_REPLACE(req, '^/[^/]+/[^/]+/f[?]p=([^:]*:){6}', '')   -- arguments in URL
            );
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN tree.app_exception THEN
        ROLLBACK;
        --
        tree.raise_error('UPDATE_SESSION_FAILED');
    WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        COMMIT;
    WHEN OTHERS THEN
        ROLLBACK;
        --
        tree.raise_error('UPDATE_SESSION_FAILED');
    END;



    PROCEDURE delete_session (
        in_session_id           sessions.session_id%TYPE,
        in_today                sessions.today%TYPE
    ) AS
        module_id               logs.log_id%TYPE;
        rows_to_delete          tree.arr_logs_log_id;
    BEGIN
        module_id := tree.log_module();
        --
        SELECT l.log_id
        BULK COLLECT INTO rows_to_delete
        FROM logs l
        WHERE l.session_id      = in_session_id
            AND l.today         = in_today;
        --
        UPDATE sessions s
        SET s.log_id            = NULL
        WHERE s.session_id      = in_session_id;
        --
        IF rows_to_delete.FIRST IS NOT NULL THEN
            FOR i IN rows_to_delete.FIRST .. rows_to_delete.LAST LOOP
                CONTINUE WHEN rows_to_delete(i) = module_id;
                --
                DELETE FROM logs_lobs       WHERE log_parent    = rows_to_delete(i);
                DELETE FROM logs_events     WHERE log_parent    = rows_to_delete(i);
                DELETE FROM logs            WHERE log_id        = rows_to_delete(i);
            END LOOP;
        END IF;
        --
        IF in_session_id != sess.get_session_id() THEN
            DELETE FROM sessions s
            WHERE s.session_id = in_session_id;
            --
            -- may throw ORA-20987: APEX - Your session has ended
            -- not even others handler can capture this
            --APEX_SESSION.DELETE_SESSION(in_session_id);
        END IF;
        --
        tree.update_timer();
    EXCEPTION
    WHEN OTHERS THEN
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
        SELECT MIN(s.apex_items) KEEP (DENSE_RANK FIRST ORDER BY s.created_at DESC) INTO out_payload
        FROM sessions s
        WHERE s.user_id         = COALESCE(in_user_id, sess.get_user_id())
            AND s.app_id        = COALESCE(in_app_id,  sess.get_app_id(), s.app_id)
            AND s.session_id    != sess.get_session_id();
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
        PRAGMA UDF;
    BEGIN
        RETURN FLOOR((in_date - TRUNC(in_date)) * 1440 / in_interval) + 1;
    END;



    PROCEDURE update_calendar (
        in_app_id           calendar.app_id%TYPE        := NULL
    ) AS
    BEGIN
        tree.log_module(in_app_id);
        --
        INSERT INTO calendar (app_id, today, today__)
        VALUES (
            COALESCE(in_app_id, sess.get_app_id()),
            TO_CHAR(SYSDATE + 1, 'YYYY-MM-DD'),
            TRUNC(SYSDATE) + 1
        );
    EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;

END;
/

