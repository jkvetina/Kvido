CREATE OR REPLACE PACKAGE BODY apex AS

    FUNCTION is_developer (
        in_username         VARCHAR2
    )
    RETURN BOOLEAN AS
        valid               VARCHAR2(1);
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



    FUNCTION get_developer_session_id
    RETURN apex_workspace_sessions.apex_session_id%TYPE
    AS
        session_id          apex_workspace_sessions.apex_session_id%TYPE;
    BEGIN
        SELECT MIN(s.apex_session_id) KEEP (DENSE_RANK FIRST ORDER BY s.session_created DESC)
        INTO session_id
        FROM apex_workspace_developers d
        JOIN apex_applications a
            ON a.workspace                  = d.workspace_name
        JOIN apex_workspace_sessions m
            ON m.apex_session_id            = sess.get_session_id()
            AND m.workspace_name            = d.workspace_name
        JOIN apex_workspace_sessions s
            ON s.workspace_id               = m.workspace_id
            --AND s.remote_addr               = m.remote_addr       -- sadly this may not match
            AND s.apex_session_id           != m.apex_session_id
            AND UPPER(s.user_name)          IN (UPPER(d.user_name), UPPER(d.email))
        WHERE a.application_id              = sess.get_app_id()
            AND d.is_application_developer  = 'Yes'
            AND d.account_locked            = 'No'
            AND UPPER(sess.get_user_id())   IN (UPPER(d.user_name), UPPER(d.email));
        --
        RETURN session_id;
    END;



    FUNCTION check_item_name (
        in_name             VARCHAR2
    )
    RETURN VARCHAR2 AS
        out_item_name       VARCHAR2(30)    := '';
        out_item_exists     CHAR(1)         := 'N';
    BEGIN
        out_item_name       := REPLACE(in_name, apex.item_prefix, 'P' || sess.get_page_id() || '_');
        --
        IF NOT apex.is_developer() THEN
            RETURN out_item_name;
        END IF;

        -- check item existence to avoid hidden errors
        IF out_item_name LIKE 'P%' THEN
            BEGIN
                SELECT 'Y' INTO out_item_exists
                FROM apex_application_page_items p
                WHERE p.application_id      = sess.get_app_id()
                    AND p.page_id           = sess.get_page_id()
                    AND p.item_name         = out_item_name;
                --
                RETURN out_item_name;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            END;
        END IF;
        --
        BEGIN
            SELECT 'Y' INTO out_item_exists
            FROM apex_application_items g
            WHERE g.application_id      = sess.get_app_id()
                AND g.item_name         = out_item_name;
            --
            RETURN out_item_name;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        END;
        --
        tree.log_error('APEX_ITEM_NOT_FOUND', in_name, out_item_name);
        --
        RETURN NULL;
    END;



    PROCEDURE set_item (
        in_name             VARCHAR2,
        in_value            VARCHAR2        := NULL
    ) AS
        item_name           VARCHAR2(30);
    BEGIN
        item_name := apex.check_item_name(in_name);
        --
        IF item_name IS NOT NULL THEN
            APEX_UTIL.SET_SESSION_STATE(item_name, in_value);
        END IF;
    END;



    FUNCTION get_item (
        in_name             VARCHAR2
        --
        -- @TODO: OVERLOAD NUMBER, DATE
        --
    )
    RETURN VARCHAR2 AS
        item_name           VARCHAR2(30);
    BEGIN
        item_name := apex.check_item_name(in_name);
        --
        IF item_name IS NOT NULL THEN
            RETURN APEX_UTIL.GET_SESSION_STATE(item_name);
        END IF;
        --
        RETURN NULL;
    END;



    PROCEDURE clear_items AS
        req                 VARCHAR2(4000) := SUBSTR(sess.get_request(), 1, 4000);
    BEGIN
        -- delete page items one by one, except items passed in query string
        FOR c IN (
            SELECT i.item_name
            FROM apex_application_page_items i
            WHERE i.application_id  = sess.get_app_id()
                AND i.page_id       = sess.get_page_id()
                AND (
                    NOT REGEXP_LIKE(req, '[:,]' || i.item_name || '[,:]')       -- for legacy
                    AND NOT REGEXP_LIKE(req, LOWER(i.item_name) || '[=&]')      -- for friendly url
                )
        ) LOOP
            apex.set_item(c.item_name, NULL);
        END LOOP;
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
        out_target      VARCHAR2(32767);
    BEGIN
        -- commit otherwise anything before redirect will be rolled back
        COMMIT;

        -- check if we are in APEX or not
        HTP.INIT;
        out_target := apex.get_page_link (
            in_page_id  => in_page_id,
            in_names    => in_names,
            in_values   => in_values
        );
        --
        tree.log_module(in_page_id, in_names, in_values, out_target);
        --
        APEX_UTIL.REDIRECT_URL(out_target);  -- OWA_UTIL not working on Cloud
        --
        APEX_APPLICATION.STOP_APEX_ENGINE;
        --
        -- EXCEPTION
        -- WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        --
    END;



    PROCEDURE redirect_with_items (
        in_page_id      NUMBER      := NULL
    ) AS
        out_names       VARCHAR2(4000);
        out_values      VARCHAR2(4000);
        out_target      VARCHAR2(32767);
    BEGIN
        -- commit otherwise anything before redirect will be rolled back
        COMMIT;

        -- get page items with not null values
        FOR c IN (
            SELECT
                p.item_name,
                apex.get_item(p.item_name)      AS item_value
            FROM apex_application_page_items p
            WHERE p.application_id              = sess.get_app_id()
                AND p.page_id                   = COALESCE(in_page_id, sess.get_page_id())
                AND apex.get_item(p.item_name)  IS NOT NULL
        ) LOOP
            out_names   := out_names  || c.item_name  || ',';
            out_values  := out_values || c.item_value || ',';
        END LOOP;

        -- check if we are in APEX or not
        HTP.INIT;
        out_target := apex.get_page_link (
            in_page_id  => in_page_id,
            in_names    => out_names,
            in_values   => out_values
        );
        --
        tree.log_module(in_page_id, out_names, out_values, out_target);
        --
        APEX_UTIL.REDIRECT_URL(out_target);  -- OWA_UTIL not working on Cloud
        --
        APEX_APPLICATION.STOP_APEX_ENGINE;
        --
        -- EXCEPTION
        -- WHEN APEX_APPLICATION.E_STOP_APEX_ENGINE THEN
        --
    END;



    FUNCTION get_page_link (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        --
        -- @TODO: $NAME -> P###_
        --
        in_values       VARCHAR2    := NULL
        --
        -- @TODO: in_attach_globals
        --
    )
    RETURN VARCHAR2 AS
        reset_item      apex_application_page_items.item_name%TYPE;
        out_page_id     navigation.page_id%TYPE;
        out_names       VARCHAR2(32767);
        out_values      VARCHAR2(32767);
    BEGIN
        out_page_id     := COALESCE(in_page_id, sess.get_page_id());
        out_names       := in_names;
        out_values      := in_values;

        -- check existance of reset item on target page
        SELECT MAX(i.item_name) INTO reset_item
        FROM apex_application_page_items i
        WHERE i.application_id  = sess.get_app_id()
            AND i.page_id       = out_page_id
            AND i.item_name     = 'P' || out_page_id || '_RESET';

        -- autofill missing values
        IF in_names IS NOT NULL AND in_values IS NULL THEN
            FOR c IN (
                SELECT item_name
                FROM (
                    SELECT DISTINCT REGEXP_SUBSTR(in_names, '[^,]+', 1, LEVEL) AS item_name, LEVEL AS order#
                    FROM DUAL
                    CONNECT BY LEVEL <= REGEXP_COUNT(in_names, ',') + 1
                )
                ORDER BY order# DESC
            ) LOOP
                out_values := apex.get_item(c.item_name) || ',' || out_values;
            END LOOP;
        END IF;

        -- auto add reset item to args if not passed already
        IF reset_item IS NOT NULL AND NVL(INSTR(out_names, reset_item), 0) = 0 THEN
            out_names   := reset_item || ',' || out_names;
            out_values  := 'Y,' || out_values;
        END IF;

        -- generate url
        RETURN APEX_PAGE.GET_URL (
            p_page      => out_page_id,
            p_items     => out_names,
            p_values    => out_values
        );
    EXCEPTION
    WHEN OTHERS THEN
        tree.raise_error('INTERNAL_ERROR', in_page_id, in_names, in_values);
    END;



    FUNCTION get_developer_page_link (
        in_page_id      NUMBER,
        in_region_id    NUMBER          := NULL
    )
    RETURN VARCHAR2 AS
        in_app_id       CONSTANT navigation.app_id%TYPE         := sess.get_app_id();
    BEGIN
        RETURN '<a href="' ||
            APEX_PAGE.GET_URL (
                p_application   => '4000',
                p_page          => '4500',
                p_session       => apex.get_developer_session_id(),
                p_clear_cache   => '1,4150',
                p_items         => 'FB_FLOW_ID,FB_FLOW_PAGE_ID,F4000_P1_FLOW,F4000_P4150_GOTO_PAGE,F4000_P1_PAGE',
                p_values        => in_app_id || ',' || in_page_id || ',' || in_app_id || ',' || in_page_id || ',' || in_page_id
            ) ||
            CASE WHEN in_region_id IS NOT NULL THEN '::#5110:' || in_region_id END ||  -- focus region
            '">' || apex.get_icon('fa-file-code-o', 'Open page in APEX') || '</a>';
    EXCEPTION
    WHEN OTHERS THEN
        tree.raise_error('INTERNAL_ERROR', in_page_id, in_region_id);
    END;



    FUNCTION get_icon (
        in_name         VARCHAR2,
        in_title        VARCHAR2    := NULL
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN '<span class="fa ' || in_name || '" title="' || in_title || '"></span>';
    END;

END;
/
