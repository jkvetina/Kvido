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
    format_date         CONSTANT VARCHAR2(30)           := 'YYYY-MM-DD';
    format_date_time    CONSTANT VARCHAR2(30)           := 'YYYY-MM-DD HH24:MI:SS';

    -- pages available to users
    app_min_page        CONSTANT sessions.page_id%TYPE  := 1;
    app_max_page        CONSTANT sessions.page_id%TYPE  := 999;





    -- ### Introduction
    --
    -- Best way to start is with [`sessions`](./tables-sessions) table.
    --





    -- ### Application getters
    --

    --
    -- Returns APEX application id
    --
    FUNCTION get_app_id
    RETURN sessions.app_id%TYPE;



    --
    -- Returns current user id (APEX, SYS_CONTEXT, DB...)
    --
    FUNCTION get_user_id
    RETURN sessions.user_id%TYPE;



    --
    -- Returns user lang
    --
    FUNCTION get_user_lang
    RETURN users.lang%TYPE;



    --
    -- Returns APEX page id
    --
    FUNCTION get_page_id
    RETURN sessions.page_id%TYPE;



    --
    -- Returns APEX page group name
    --
    FUNCTION get_page_group
    RETURN apex_application_pages.page_group%TYPE;



    --
    -- Returns APEX session id
    --
    FUNCTION get_session_id
    RETURN sessions.session_id%TYPE;



    --
    -- Returns database session id
    --
    FUNCTION get_session_db
    RETURN sessions.session_db%TYPE;



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
    -- Initialize session and keep resp. set user_id
    --
    PROCEDURE init_session (
        in_user_id          sessions.user_id%TYPE
    );



    --
    -- Set user_id and items from previous session
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE
    );



    --
    -- Set user_id outside of APEX (from console, trigger, job...)
    --
    PROCEDURE create_session (
        in_user_id          sessions.user_id%TYPE,
        in_app_id           sessions.app_id%TYPE,
        in_page_id          sessions.page_id%TYPE       := 0
    );



    --
    -- Store current APEX items and activity to `sessions`
    --
    PROCEDURE update_session (
        in_note             VARCHAR2                    := NULL
    );



    --
    -- Load session items from recent session
    --
    FUNCTION get_recent_items (
        in_user_id          sessions.user_id%TYPE       := NULL,
        in_app_id           sessions.app_id%TYPE        := NULL
    )
    RETURN sessions.apex_items%TYPE;





    -- ### Little helpers
    --

    --
    -- Returns `TRUE` if user has passed requested role
    --
    FUNCTION get_role_status (
        in_role_id          user_roles.role_id%TYPE,
        in_user_id          user_roles.user_id%TYPE     := NULL,
        in_app_id           user_roles.app_id%TYPE      := NULL
    )
    RETURN BOOLEAN;

END;
/
