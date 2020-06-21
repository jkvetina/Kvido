CREATE OR REPLACE PACKAGE ctx AS

    -- context namespace
    app_namespace       CONSTANT VARCHAR2(30)       := 'APP';

    -- context name for user_id
    app_user_id         CONSTANT VARCHAR2(30)       := 'USER_ID';

    -- application contexts
    app_context_a       CONSTANT VARCHAR2(30)       := 'CONTEXT_A';
    app_context_b       CONSTANT VARCHAR2(30)       := 'CONTEXT_B';
    app_context_c       CONSTANT VARCHAR2(30)       := 'CONTEXT_C';



    --
    -- Returns application id from APEX
    --
    FUNCTION get_app_id
    RETURN logs.app_id%TYPE;



    --
    -- Returns application page id from APEX
    --
    FUNCTION get_page_id
    RETURN logs.page_id%TYPE;



    --
    -- Returns user id (APEX user, CONTEXT user, DB user..., whatever fits your needs)
    --
    FUNCTION get_user_id
    RETURN logs.user_id%TYPE;



    --
    -- Set user_id when running from DBMS_SCHEDULER, trigger...
    --
    PROCEDURE set_user_id (
        in_user_id  logs.user_id%TYPE
    );



    --
    -- Returns database session id
    --
    FUNCTION get_session_db
    RETURN logs.session_db%TYPE;



    --
    -- Returns APEX session id
    --
    FUNCTION get_session_apex
    RETURN logs.session_apex%TYPE;



    --
    -- Returns your app context id
    --
    FUNCTION get_context_a
    RETURN logs.context_a%TYPE;



    --
    -- Set application context
    --
    PROCEDURE set_context_a (
        in_value    logs.context_a%TYPE
    );



    --
    -- Returns your app context id
    --
    FUNCTION get_context_b
    RETURN logs.context_b%TYPE;



    --
    -- Set application context
    --
    PROCEDURE set_context_b (
        in_value    logs.context_b%TYPE
    );



    --
    -- Returns your app context id
    --
    FUNCTION get_context_c
    RETURN logs.context_c%TYPE;



    --
    -- Set application context
    --
    PROCEDURE set_context_c (
        in_value    logs.context_c%TYPE
    );

END;
/

