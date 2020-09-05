CREATE OR REPLACE PACKAGE ctx AS

    /**
     * This package is part of the BUG project under MIT licence.
     * https://github.com/jkvetina/BUG/
     *
     * Copyright (c) Jan Kvetina, 2020
     */



    -- context namespace
    app_namespace       CONSTANT VARCHAR2(30)       := 'APP';

    -- context name for user_id
    app_user_attr       CONSTANT VARCHAR2(30)       := 'USER_ID__';
    app_user            CONSTANT VARCHAR2(30)       := USER;

    -- splitters for payload
    splitter_values     CONSTANT CHAR := '=';
    splitter_rows       CONSTANT CHAR := '|';

    -- internal date formats
    format_date         CONSTANT VARCHAR2(30)   := 'YYYY-MM-DD';
    format_date_time    CONSTANT VARCHAR2(30)   := 'YYYY-MM-DD HH24:MI:SS';





    -- ### Introduction
    --
    -- Best way to start is with [`contexts`](./tables-contexts) table.
    --





    -- ### Initialization
    --

    --
    -- Initialize contexts and `DBMS_SESSION` things
    --
    PROCEDURE init__
    ACCESSIBLE BY (
        PACKAGE ctx,
        PACKAGE ctx_ut
    );



    --
    -- Set user_id and contexts from previous session
    --
    PROCEDURE set_user_id (
        in_user_id          logs.user_id%TYPE       := NULL
    );



    --
    -- Set user_id and set contexts from payload
    --
    PROCEDURE set_user_id (
        in_user_id          logs.user_id%TYPE,
        in_payload          contexts.payload%TYPE
    );



    --
    -- Store current contexts to `contexts` table
    --
    PROCEDURE save_contexts;



    --
    -- Store contexts into `logs.log_id` for `bug.log_scheduler`
    --
    PROCEDURE save_contexts (
        in_log_id           logs.log_id%TYPE
    );





    -- ### Basic functionality
    --

    --
    -- Returns desired app context as string
    --
    FUNCTION get_context (
        in_name     VARCHAR2,
        in_format   VARCHAR2    := NULL,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN VARCHAR2;



    --
    -- Returns desired app context as `NUMBER`
    --
    FUNCTION get_context_number (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN NUMBER;



    --
    -- Returns desired app context as `DATE`
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
        in_value    VARCHAR2        := NULL
    );



    --
    -- Set application context value (date)
    --
    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    DATE
    );





    -- ### Getters for `bug` package
    --

    --
    -- Returns current user id (APEX user, CONTEXT user, DB user..., whatever fits your needs)
    --
    FUNCTION get_user_id
    RETURN logs.user_id%TYPE;



    --
    -- Returns APEX application id
    --
    FUNCTION get_app_id
    RETURN logs.app_id%TYPE;



    --
    -- Returns APEX page id
    --
    FUNCTION get_page_id
    RETURN logs.page_id%TYPE;



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
    -- Returns client_id for `DBMS_SESSION`
    --
    FUNCTION get_client_id (
        in_user_id          contexts.user_id%TYPE := NULL
    )
    RETURN VARCHAR2;





    -- ### Storing and retrieving contexts, more like for internal use
    --

    --
    -- Prepare/get payload from current contexts
    --
    FUNCTION get_payload
    RETURN contexts.payload%TYPE;



    --
    -- Parse/set payload as current contexts (available thru `SYS_CONTEXT`)
    --
    PROCEDURE apply_payload (
        in_payload          contexts.payload%TYPE
    );



    --
    -- Load/get contexts from `contexts` table and set them as current
    --
    PROCEDURE load_contexts (
        in_user_id          contexts.user_id%TYPE       := NULL,
        in_app_id           contexts.app_id%TYPE        := NULL,
        in_session_db       contexts.session_db%TYPE    := NULL,
        in_session_apex     contexts.session_apex%TYPE  := NULL
    );

END;
/
