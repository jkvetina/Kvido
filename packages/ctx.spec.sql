CREATE OR REPLACE PACKAGE ctx AS

    -- context namespace
    app_namespace       CONSTANT VARCHAR2(30)       := 'APP';

    -- context name for user_id
    app_user_id         CONSTANT VARCHAR2(30)       := 'USER_ID';

    -- splitters for payload
    splitter_values     CONSTANT CHAR := '=';
    splitter_rows       CONSTANT CHAR := '|';



    --
    -- Initialize session
    --
    PROCEDURE init;



    --
    -- Returns application id from APEX
    --
    FUNCTION get_app_id
    RETURN debug_log.app_id%TYPE;



    --
    -- Returns application page id from APEX
    --
    FUNCTION get_page_id
    RETURN debug_log.page_id%TYPE;



    --
    -- Returns user id (APEX user, CONTEXT user, DB user..., whatever fits your needs)
    --
    FUNCTION get_user_id
    RETURN debug_log.user_id%TYPE;



    --
    -- Set user_id when running from DBMS_SCHEDULER, trigger...
    --
    PROCEDURE set_user_id (
        in_user_id  debug_log.user_id%TYPE
    );



    --
    -- Returns database session id
    --
    FUNCTION get_session_db
    RETURN debug_log.session_db%TYPE;



    --
    -- Returns APEX session id
    --
    FUNCTION get_session_apex
    RETURN debug_log.session_apex%TYPE;



    --
    -- Returns client_id for DBMS_SESSION
    --
    FUNCTION get_client_id (
        in_user_id      contexts.user_id%TYPE := NULL
    )
    RETURN VARCHAR2;



    --
    -- Returns your app context
    --
    FUNCTION get_context (
        in_name     VARCHAR2,
        in_format   VARCHAR2    := NULL,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN VARCHAR2;



    --
    -- Returns your app context as NUMBER
    --
    FUNCTION get_context_number (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN NUMBER;



    --
    -- Returns your app context as DATE
    --
    FUNCTION get_context_date (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN DATE;



    --
    -- Set application context value
    --
    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    VARCHAR2
    );



    --
    -- Load contexts from table
    --
    PROCEDURE get_contexts (
        in_app_id           contexts.app_id%TYPE        := NULL,
        in_user_id          contexts.user_id%TYPE       := NULL,
        in_session_db       contexts.session_db%TYPE    := NULL,
        in_session_apex     contexts.session_apex%TYPE  := NULL
    );



    --
    -- Parse payload and store it in SYS_CONTEXT
    --
    PROCEDURE set_contexts (
        in_payload          contexts.payload%TYPE
    );



    --
    -- Store current contexts into table
    --
    PROCEDURE update_contexts;



    --
    -- Prepare payload with contexts
    --
    FUNCTION get_payload
    RETURN contexts.payload%TYPE;

END;
/

