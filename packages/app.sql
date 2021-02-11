CREATE OR REPLACE PACKAGE BODY app AS

    FUNCTION get_env_name
    RETURN VARCHAR2 AS
        out_name VARCHAR2(4000);
    BEGIN
        out_name := 'Environment: ' || 'DEV';  -- retrieve value from settings
        --
        IF apex.is_developer() THEN
            -- details for developers
            SELECT
                'Oracle APEX: '     || a.version_no     || CHR(10) ||
                'Oracle Database: ' || p.version_full   || CHR(10) ||
                out_name
            INTO out_name
            FROM apex_release a
            CROSS JOIN product_component_version p;
        END IF;
        --
        RETURN apex.get_icon('fa-window-bookmark', out_name);
    END;



    FUNCTION get_user_name
    RETURN users.user_login%TYPE AS
        out_name        users.user_login%TYPE;
    BEGIN
        SELECT COALESCE(u.user_name, u.user_login, u.user_id) INTO out_name
        FROM users u
        WHERE u.user_id = sess.get_user_id();
        --
        RETURN out_name;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN sess.get_user_id();
    END;



    FUNCTION get_date
    RETURN DATE AS
    BEGIN
        RETURN TO_DATE(COALESCE(apex.get_item('G_DATE'), SYSDATE), sess.format_date);
    EXCEPTION
    WHEN OTHERS THEN
        --IF SQLCODE = -1858 THEN  -- alternative format
        RAISE;
    END;



    FUNCTION get_date_str
    RETURN VARCHAR2 AS
    BEGIN
        RETURN COALESCE(apex.get_item('G_DATE'), TO_CHAR(SYSDATE, sess.format_date));
    END;



    FUNCTION manipulate_page_label (
        in_page_name VARCHAR2
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN REPLACE(REPLACE(REPLACE(REPLACE(in_page_name,
            '${DATE}',          app.get_date_str()),
            '${USER_NAME}',     app.get_user_name()),
            '${ENV_NAME}',      app.get_env_name()),
            '${LOGOUT}',        apex.get_icon('fa-coffee', 'Logout')  -- app.get_logout_label
        );
    END;

END;
/
