CREATE OR REPLACE PACKAGE app AS

    FUNCTION get_env_name
    RETURN VARCHAR2;



    FUNCTION get_user_name
    RETURN users.user_login%TYPE;



    FUNCTION get_user_lang
    RETURN users.lang_id%TYPE;



    FUNCTION get_date
    RETURN DATE;



    FUNCTION get_date_str
    RETURN VARCHAR2;



    PROCEDURE set_date (
        in_date             DATE
    );



    PROCEDURE set_date_str (
        in_date             VARCHAR2
    );



    FUNCTION manipulate_page_label (
        in_page_name        VARCHAR2
    )
    RETURN VARCHAR2;



    FUNCTION get_duration (
        in_interval         INTERVAL DAY TO SECOND
    )
    RETURN VARCHAR2;



    FUNCTION get_duration (
        in_interval         NUMBER
    )
    RETURN VARCHAR2;

END;
/
