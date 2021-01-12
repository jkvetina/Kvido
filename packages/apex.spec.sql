CREATE OR REPLACE PACKAGE apex AS

    /**
     * This package is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     */



    -- ### Functions to work with APEX items
    --

    --
    -- Set item
    --
    PROCEDURE set_item (
        in_name         VARCHAR2,
        in_value        VARCHAR2
    );



    --
    -- Get (global and page) item
    --
    FUNCTION get_item (
        in_name         VARCHAR2
    )
    RETURN VARCHAR2;



    --
    -- Clear requested, all or not used items on page
    --
    PROCEDURE clear_items (
        in_items        VARCHAR2 := NULL
        --
        -- NULL = all except passed in args
        -- %    = all
        -- list = only items on list
        --
    );



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
    -- Get link to page with items
    --
    FUNCTION get_page_link (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    )
    RETURN VARCHAR2;

END;
/
