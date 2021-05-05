CREATE OR REPLACE PACKAGE sess AS

    /**
     * This package is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     *
     *                                                      (R)
     *                      ---                  ---
     *                    #@@@@@@              &@@@@@@
     *                    @@@@@@@@     .@      @@@@@@@@
     *          -----      @@@@@@    @@@@@@,   @@@@@@@      -----
     *       &@@@@@@@@@@@    @@@   &@@@@@@@@@.  @@@@   .@@@@@@@@@@@#
     *           @@@@@@@@@@@   @  @@@@@@@@@@@@@  @   @@@@@@@@@@@
     *             \@@@@@@@@@@   @@@@@@@@@@@@@@@   @@@@@@@@@@
     *               @@@@@@@@@   @@@@@@@@@@@@@@@  &@@@@@@@@
     *                 @@@@@@@(  @@@@@@@@@@@@@@@  @@@@@@@@
     *                  @@@@@@(  @@@@@@@@@@@@@@,  @@@@@@@
     *                  .@@@@@,   @@@@@@@@@@@@@   @@@@@@
     *                   @@@@@@  *@@@@@@@@@@@@@   @@@@@@
     *                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
     *                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     *                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@
     *                     .@@@@@@@@@@@@@@@@@@@@@@@@@
     *                       .@@@@@@@@@@@@@@@@@@@@@
     *                            jankvetina.cz
     *                               -------
     *
     */



    -- internal date formats
    format_date             CONSTANT VARCHAR2(30)                       := 'YYYY-MM-DD';
    format_date_time        CONSTANT VARCHAR2(30)                       := 'YYYY-MM-DD HH24:MI:SS';

    -- pages available to users
    app_min_page            CONSTANT sessions.page_id%TYPE              := 1;
    app_max_page            CONSTANT sessions.page_id%TYPE              := 999;

    -- anonymous user used on login pages in APEX
    anonymous_user          CONSTANT VARCHAR2(30)                       := 'NOBODY';  -- ORDS_PUBLIC_USER

    -- login page
    login_page#             CONSTANT NUMBER(6)                          := 9999;
    




    -- ### Introduction
    --
    -- Best way to start is with [`sessions`](./tables-sessions) table.
    --





    -- ### Application getters
    --

    --
    -- Return APEX log_id created at start of the page
    --
    FUNCTION get_apex_log_id
    RETURN logs.log_id%TYPE;



    --
    -- Returns APEX application id
    --
    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE;



    --
    -- Returns current user id (APEX, SYS_CONTEXT, DB...)
    --
    FUNCTION get_user_id
    RETURN users.user_id%TYPE;



    --
    -- Set (shorten) user_id after authentification
    --
    PROCEDURE set_user_id
    ACCESSIBLE BY (
        PACKAGE sess,
        PACKAGE sess_ut
    );



    --
    -- Transform user name
    --
    FUNCTION get_user_name (
        in_user_id          sessions.user_id%TYPE       := NULL
    )
    RETURN users.user_name%TYPE;



    --
    -- Returns APEX page id
    --
    FUNCTION get_page_id
    RETURN sessions.page_id%TYPE;



    --
    -- Returns APEX page group name for requested or current page
    --
    FUNCTION get_page_group (
        in_page_id          sessions.page_id%TYPE       := NULL
    )
    RETURN apex_application_pages.page_group%TYPE;



    --
    -- Returns root page ID for requested or current page
    --
    FUNCTION get_root_page_id (
        in_page_id          sessions.page_id%TYPE       := NULL
    )
    RETURN apex_application_pages.page_id%TYPE;



    --
    -- Returns APEX session id
    --
    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE;



    --
    -- Returns database session id
    --
    FUNCTION get_session_db
    RETURN NUMBER;



    --
    -- Returns client_id for `DBMS_SESSION`
    --
    FUNCTION get_client_id (
        in_user_id          sessions.user_id%TYPE       := NULL
    )
    RETURN VARCHAR2;



    --
    -- Returns requested URL
    --
    FUNCTION get_request
    RETURN VARCHAR2;





    -- ### Initialization
    --

    --
    -- Initialize session
    --
    PROCEDURE init_session;



    --
    -- Clear session at the end
    --
    PROCEDURE clear_session (
        in_log_id       logs.log_id%TYPE        := NULL
    );



    --
    -- Create session from APEX, set user_id and items from previous session
    --
    PROCEDURE create_session;



    --
    -- Create session outside of APEX (from console, trigger, job...)
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := 0
    );



    --
    -- Store current APEX items and activity to `sessions`
    --
    PROCEDURE update_session;



    --
    -- Delete logs for requested session
    --
    PROCEDURE delete_session (
        in_session_id       sessions.session_id%TYPE,
        in_today            sessions.today%TYPE
    );



    --
    -- Force APEX to create new session
    --
    PROCEDURE force_new_session;



    --
    -- Load session items from recent session
    --
    FUNCTION get_recent_items (
        in_user_id          sessions.user_id%TYPE       := NULL,
        in_app_id           sessions.app_id%TYPE        := NULL
    )
    RETURN sessions.apex_items%TYPE;



    --
    -- Convert date or timestamp into time bucket
    --
    FUNCTION get_time_bucket (
        in_date             DATE,
        in_interval         NUMBER
    )
    RETURN NUMBER
    RESULT_CACHE;



    --
    -- Prepare rows in Calendar table
    --
    PROCEDURE update_calendar (
        in_app_id           calendar.app_id%TYPE        := NULL
    );

END;
/
