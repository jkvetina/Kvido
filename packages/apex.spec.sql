CREATE OR REPLACE PACKAGE apex AS

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

    item_prefix     CONSTANT VARCHAR2(4)        := '$';  -- transform $NAME to P500_NAME if current page_id = 500





    -- ### Auth functions
    --

    --
    -- Check if current/requested user is APEX developer
    --
    FUNCTION is_developer (
        in_username     VARCHAR2        := NULL
    )
    RETURN BOOLEAN;



    --
    -- Check if DEBUG is on
    --
    FUNCTION is_debug
    RETURN BOOLEAN;



    --
    -- Find current session_id for Developer in APEX
    --
    FUNCTION get_developer_session_id
    RETURN apex_workspace_sessions.apex_session_id%TYPE;





    -- ### Functions to work with APEX items
    --

    --
    -- Set item
    --
    PROCEDURE set_item (
        in_name         VARCHAR2,
        in_value        VARCHAR2        := NULL
    );



    --
    -- Get (global and page) item
    --
    FUNCTION get_item (
        in_name         VARCHAR2
    )
    RETURN VARCHAR2;



    --
    -- Clear page items except items passed in url
    --
    PROCEDURE clear_items;



    --
    -- Apply values from JSON object keys to items
    --
    PROCEDURE apply_items (
        in_items            sessions.apex_items%TYPE
    );



    --
    -- Get items for selected/current page as JSON object
    --
    FUNCTION get_page_items (
        in_page_id          logs.page_id%TYPE       := NULL,
        in_filter           logs.arguments%TYPE     := '%'
    )
    RETURN sessions.apex_items%TYPE;



    --
    -- Get global (app) items as JSON object
    --
    FUNCTION get_global_items (
        in_filter           logs.arguments%TYPE     := '%'
    )
    RETURN sessions.apex_items%TYPE;





    -- ### Functions to work with pages
    --

    --
    -- Redirect to page and set items if needed
    --
    PROCEDURE redirect (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    );



    --
    -- Redirect to page and set all items from page witn NOT NULL values
    --
    PROCEDURE redirect_with_items (
        in_page_id      NUMBER      := NULL
    );



    --
    -- Get link to page with items
    --
    FUNCTION get_page_link (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    )
    RETURN VARCHAR2;



    --
    -- Get link to APEX Developer to show requested page
    --
    FUNCTION get_developer_page_link (
        in_page_id      NUMBER,
        in_region_id    NUMBER          := NULL
    )
    RETURN VARCHAR2;



    --
    -- Get icon
    --
    FUNCTION get_icon (
        in_name         VARCHAR2,
        in_title        VARCHAR2    := NULL
    )
    RETURN VARCHAR2;

END;
/
