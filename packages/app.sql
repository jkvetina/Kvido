CREATE OR REPLACE PACKAGE BODY app AS

    FUNCTION manipulate_page_label (
        in_page_name VARCHAR2
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN REPLACE(REPLACE(REPLACE(REPLACE(in_page_name,
            '${DATE}',          app.get_date_str()),
            '${USER_NAME}',     sess.get_user_id()),
            '${ENV_NAME}',      app.get_env_name()),
            '${LOGOUT}',        '<span class="fa fa-coffee"></span>'  -- app.get_logout_label
        );
    END;

END;
/
