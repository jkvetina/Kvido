CREATE OR REPLACE PACKAGE sess AS

    /**
     * This package is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     */



    -- context namespace
    app_namespace       CONSTANT VARCHAR2(30)   := 'APP';

    -- context name for user_id
    app_user_attr       CONSTANT VARCHAR2(30)   := 'USER_ID__';
    app_user            CONSTANT VARCHAR2(30)   := USER;

    -- splitters for payload
    splitter_values     CONSTANT CHAR           := '=';
    splitter_rows       CONSTANT CHAR           := '|';

    -- internal date formats
    format_date         CONSTANT VARCHAR2(30)   := 'YYYY-MM-DD';
    format_date_time    CONSTANT VARCHAR2(30)   := 'YYYY-MM-DD HH24:MI:SS';





    -- ### Introduction
    --
    -- Best way to start is with [`sessions`](./tables-sessions) table.
    --





    -- ### Initialization
    --

    --
    -- Initialize session
    --
    PROCEDURE init_session;



    --
    -- Initialize session and keep resp. set user_id
    --
    PROCEDURE init_session (
        in_user_id          sessions.user_id%TYPE
    );



    --
    -- Set user_id and contexts from previous session
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_message          logs.message%TYPE           := NULL
    );



    --
    -- Set user_id and apply contexts from `session` table
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_contexts         sessions.contexts%TYPE,
        in_message          logs.message%TYPE           := NULL
    );



    --
    -- Set user_id and mimic requested APEX page with items
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.user_id%TYPE,
        in_message          logs.message%TYPE           := NULL
    );



    --
    -- Load/get contexts from `sessions` table and set them as current
    --
    PROCEDURE load_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := NULL,
        in_session_db       sessions.session_db%TYPE    := NULL,
        in_session_apex     sessions.session_apex%TYPE  := NULL,
        in_created_at_min   sessions.created_at%TYPE    := NULL
    );



    --
    -- Store current contexts and items to `sessions` and update `logs` table
    --
    PROCEDURE update_session (
        in_log_id           logs.log_id%TYPE            := NULL,
        in_src              sessions.src%TYPE           := NULL
    );





    -- ### Getters for `tree` package
    --

    --
    -- Returns current user id (APEX, SYS_CONTEXT, DB...)
    --
    FUNCTION get_user_id
    RETURN sessions.user_id%TYPE;



    --
    -- Returns `TRUE` if user has passed role
    --
    FUNCTION get_role_id_status (
        in_role_id          user_roles.role_id%TYPE,
        in_user_id          user_roles.user_id%TYPE     := NULL,
        in_app_id           user_roles.app_id%TYPE      := NULL
    )
    RETURN BOOLEAN;



    --
    -- Returns APEX application id
    --
    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE;



    --
    -- Returns APEX page id
    --
    FUNCTION get_page_id
    RETURN sessions.page_id%TYPE;



    --
    -- Returns database session id
    --
    FUNCTION get_session_db
    RETURN sessions.session_db%TYPE;



    --
    -- Returns APEX session id
    --
    FUNCTION get_session_apex
    RETURN sessions.session_apex%TYPE;



    --
    -- Returns recent `session_id` from `sessions` table
    --
    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE;



    --
    -- Returns client_id for `DBMS_SESSION`
    --
    FUNCTION get_client_id (
        in_user_id          sessions.user_id%TYPE       := NULL
    )
    RETURN VARCHAR2;





    -- ### Context functionality
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
        in_value    VARCHAR2    := NULL
    );



    --
    -- Set application context value (date)
    --
    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    DATE
    );





    -- ### Storing and retrieving contexts and items
    --

    --
    -- Prepare/get contexts payload from current values
    --
    FUNCTION get_contexts
    RETURN sessions.contexts%TYPE;



    --
    -- Prepare/get APEX global items
    --
    FUNCTION get_apex_globals
    RETURN sessions.apex_globals%TYPE;



    --
    -- Prepare/get current APEX page items
    --
    FUNCTION get_apex_locals
    RETURN sessions.apex_locals%TYPE;



    --
    -- Set contexts from payload (available thru `SYS_CONTEXT`)
    --
    PROCEDURE apply_contexts (
        in_contexts         sessions.contexts%TYPE,
        in_append           BOOLEAN                     := FALSE
    );



    --
    -- Parse/set APEX items
    --
    PROCEDURE apply_items (
        in_items            sessions.apex_locals%TYPE
    );

END;
/
