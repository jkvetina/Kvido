CREATE OR REPLACE PACKAGE BODY nav AS

    FUNCTION is_available (
        in_page_id              navigation.page_id%TYPE
    )
    RETURN CHAR
    AS
        auth_name               apex_application_pages.authorization_scheme%TYPE;
        proc_name               user_procedures.procedure_name%TYPE;
        proc_result             CHAR;
        --
        PRAGMA UDF;             -- SQL only
    BEGIN
        SELECT
            p.authorization_scheme,
            s.procedure_name
        INTO auth_name, proc_name
        FROM apex_application_pages p
        LEFT JOIN user_procedures s
            ON s.object_name                = nav.auth_package
            AND s.procedure_name            = p.authorization_scheme
        WHERE p.application_id              = sess.get_app_id()
            AND p.page_id                   = in_page_id
            AND p.authorization_scheme      IS NOT NULL
            AND REGEXP_LIKE(p.authorization_scheme_id, '^(\d+)$');  -- user auth schemes only
        --
        IF proc_name IS NULL THEN
            tree.log_error('AUTH_PROCEDURE_MISSING', auth_name);
            RETURN 'N';  -- hide
        END IF;
        --
        EXECUTE IMMEDIATE
            'BEGIN :r := ' || nav.auth_package || '.' || proc_name || '; END;'
            USING OUT proc_result;
        --
        RETURN NVL(proc_result, 'N');
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Y';  -- show
    END;



    FUNCTION is_visible (
        in_current_page_id      navigation.page_id%TYPE,
        in_requested_page_id    navigation.page_id%TYPE
    )
    RETURN CHAR
    AS
        requested_group         navigation_groups.page_group%TYPE;
        result_                 VARCHAR2(1);
        --
        PRAGMA UDF;             -- SQL only
    BEGIN
        -- check if requested page group exists
        requested_group := sess.get_page_group(in_requested_page_id);
        IF requested_group = sess.get_page_group(in_current_page_id) THEN
            RETURN 'Y';  -- show
        END IF;
        --
        BEGIN
            SELECT 'Y' INTO result_
            FROM navigation_groups g
            WHERE g.app_id          = sess.get_app_id()
                AND g.page_group    = requested_group
                AND ROWNUM          = 1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Y';  -- show
        END;

        -- check if current root group matches requested page group
        BEGIN
            SELECT 'Y' INTO result_
            FROM navigation_groups g
            WHERE g.app_id          = sess.get_app_id()
                AND g.page_id       = sess.get_root_page_id(in_current_page_id)
                AND g.page_group    = requested_group;
            --
            RETURN 'Y';  -- show
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'N';  -- hide
        END;
    END;



    PROCEDURE remove_missing_pages
    AS
    BEGIN
        tree.log_module();

        -- remove rows for pages which dont exists
        FOR c IN (
            SELECT n.app_id, n.page_id
            FROM p910_nav_pages_to_remove n
        ) LOOP
            tree.log_debug('DELETING', c.page_id);
            --
            DELETE FROM navigation n
            WHERE n.app_id      = c.app_id
                AND n.page_id   = c.page_id;
        END LOOP;
        --
        tree.update_timer();
    END;



    PROCEDURE add_new_pages
    AS
        rec         navigation%ROWTYPE;
    BEGIN
        tree.log_module();

        -- add pages which are present in APEX but missing in Navigation table
        FOR c IN (
            SELECT n.*
            FROM p910_nav_pages_to_add n
        ) LOOP
            tree.log_debug('ADDING', c.page_id);
            --
            rec.app_id      := c.app_id;
            rec.page_id     := c.page_id;
            rec.parent_id   := c.parent_id;
            rec.order#      := c.order#;
            rec.label       := c.label;
            rec.icon_name   := c.icon_name;
            rec.css_class   := c.css_class;
            rec.is_hidden   := c.is_hidden;
            --
            INSERT INTO navigation VALUES rec;
        END LOOP;
        --
        tree.update_timer();
    END;

END;
/

        RETURN NULL;
    END;

END;
/
