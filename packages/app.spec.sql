CREATE OR REPLACE PACKAGE app AS

    FUNCTION get_env_name
    RETURN VARCHAR2;



    FUNCTION get_user_name
    RETURN users.user_login%TYPE;



    FUNCTION get_date
    RETURN DATE;



    FUNCTION get_date_str
    RETURN VARCHAR2;



    FUNCTION manipulate_page_label (
        in_page_name VARCHAR2
    )
    RETURN VARCHAR2;

END;
/
