CREATE OR REPLACE PACKAGE BODY apex AS

    FUNCTION is_developer (
        in_username     VARCHAR2        := NULL
    )
    RETURN BOOLEAN AS
        valid           VARCHAR2(1);
    BEGIN
        SELECT 'Y' INTO valid
        FROM apex_workspace_developers d
        JOIN apex_applications a
            ON a.workspace                  = d.workspace_name
        WHERE a.application_id              = sess.get_app_id()
            AND d.is_application_developer  = 'Yes'
            AND d.account_locked            = 'No'
            AND COALESCE(in_username, sess.get_user_id()) IN (UPPER(d.user_name), LOWER(d.email));
        --
        RETURN TRUE;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;



    FUNCTION is_debug
    RETURN BOOLEAN AS
    BEGIN
        RETURN APEX_APPLICATION.G_DEBUG;
    END;



    PROCEDURE set_item (
        in_name         VARCHAR2,
        in_value        VARCHAR2        := NULL
    ) AS
    BEGIN
        APEX_UTIL.SET_SESSION_STATE(REPLACE(in_name, apex.item_prefix, 'P' || sess.get_page_id() || '_'), in_value);
    END;



    FUNCTION get_item (
        in_name         VARCHAR2
        --
        -- @TODO: OVERLOAD NUMBER, DATE
        --
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN APEX_UTIL.GET_SESSION_STATE(REPLACE(in_name, apex.item_prefix, 'P' || sess.get_page_id() || '_'));
    EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
    END;



    PROCEDURE clear_items (
        in_items        VARCHAR2 := NULL
        --
        -- NULL = all except passed in args
        -- %    = all
        -- list = only items on list
        --
    ) AS
    BEGIN
        -- delete items one by one, except items passed in query string
        IF (in_items IS NULL OR in_items = '%') THEN
            FOR c IN (
                SELECT i.item_name
                FROM apex_application_page_items i
                WHERE i.application_id  = sess.get_app_id()
                    AND i.page_id       = sess.get_page_id()
                    AND (
                        NOT REGEXP_LIKE(sess.get_request(), '[:,]' || i.item_name || '[,:]')
                        OR in_items = '%'
                    )
            ) LOOP
                APEX_UTIL.SET_SESSION_STATE(c.item_name, NULL);
            END LOOP;
        ELSE
            -- delete requested items one by one
            FOR c IN (
                SELECT i.item_name
                FROM apex_application_page_items i
                WHERE i.application_id  = sess.get_app_id()
                    AND i.page_id       = sess.get_page_id()
                    AND ',' || in_items || ',' NOT LIKE '%,' || i.item_name || ',%'
            ) LOOP
                APEX_UTIL.SET_SESSION_STATE(c.item_name, NULL);
            END LOOP;
        END IF;
    END;



    PROCEDURE apply_items (
        in_items            sessions.apex_items%TYPE
    ) AS
        json_keys           JSON_KEY_LIST;
    BEGIN
        IF in_items IS NULL THEN
            RETURN;
        END IF;
        --
        json_keys := JSON_OBJECT_T(in_items).get_keys();
        --
        FOR i IN 1 .. json_keys.COUNT LOOP
            BEGIN
                APEX_UTIL.SET_SESSION_STATE(json_keys(i), JSON_VALUE(in_items, '$.' || json_keys(i)));
            EXCEPTION
            WHEN OTHERS THEN
                NULL;
            END;
        END LOOP;
    END;



    FUNCTION get_page_items (
        in_page_id          logs.page_id%TYPE       := NULL,
        in_filter           logs.arguments%TYPE     := '%'
    )
    RETURN sessions.apex_items%TYPE AS
        out_payload         sessions.apex_items%TYPE;
    BEGIN
        SELECT JSON_OBJECTAGG(t.item_name VALUE APEX_UTIL.GET_SESSION_STATE(t.item_name) ABSENT ON NULL)
        INTO out_payload
        FROM apex_application_page_items t
        WHERE t.application_id  = sess.get_app_id()
            AND t.page_id       = COALESCE(in_page_id, sess.get_page_id())
            AND t.item_name     LIKE in_filter;
        --
        RETURN out_payload;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_global_items (
        in_filter           logs.arguments%TYPE     := '%'
    )
    RETURN sessions.apex_items%TYPE AS
        out_payload         sessions.apex_items%TYPE;
    BEGIN
        SELECT JSON_OBJECTAGG(t.item_name VALUE APEX_UTIL.GET_SESSION_STATE(t.item_name) ABSENT ON NULL)
        INTO out_payload
        FROM apex_application_items t
        WHERE t.application_id  = sess.get_app_id()
            AND t.item_name     LIKE in_filter;
        --
        RETURN out_payload;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    PROCEDURE redirect (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    ) AS
        target_url      VARCHAR2(32767);
    BEGIN
        tree.log_module(in_page_id, in_names, in_values);
        --
        COMMIT;  -- otherwise anything before redirect will be rolled back

        -- check if we are in APEX or not
        HTP.INIT;
        target_url := apex.get_page_link (
            in_page_id,
            in_names    => in_names,
            in_values   => in_values
        );
        --
        tree.log_result(target_url);
        tree.update_timer();
        --
        OWA_UTIL.REDIRECT_URL(target_url);
        --
        APEX_APPLICATION.STOP_APEX_ENGINE;
        --WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
    END;



    FUNCTION get_page_link (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    )
    RETURN VARCHAR2 AS
        out_values      VARCHAR2(32767) := '';
    BEGIN
        IF in_names IS NOT NULL AND in_values IS NULL THEN
            -- loop thru in_names, find page item value, build output string
            FOR c IN (
                SELECT *
                FROM (
                    SELECT DISTINCT REGEXP_SUBSTR(in_names, '[^,]+', 1, LEVEL) AS item_name, LEVEL AS order#
                    FROM DUAL
                    CONNECT BY LEVEL <= REGEXP_COUNT(in_names, ',') + 1
                )
                ORDER BY order#
            ) LOOP
                out_values := ',' || apex.get_item(c.item_name);
            END LOOP;
        END IF;
        --
        -- @TODO: THERE IS A BETTER WAY HOW TO DO THIS
        --
        RETURN 'f?p=' ||
            sess.get_app_id() || ':' ||
            COALESCE(in_page_id, sess.get_page_id()) || ':' ||
            sess.get_session_id() || '::' ||
            V('APP_DEBUG') || '::' ||
            in_names || ':' || COALESCE(in_values, out_values);
    END;

END;
/
