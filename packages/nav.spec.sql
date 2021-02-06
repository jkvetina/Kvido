CREATE OR REPLACE PACKAGE nav AS

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



    -- name of AUTH package
    auth_package                CONSTANT VARCHAR2(30)               := 'AUTH';

    -- specify page_id and items used for navigation peeking
    peek_page_id                CONSTANT navigation.page_id%TYPE    := 910;
    peek_page_item              CONSTANT VARCHAR2(30)               := 'P910_PEEK_PAGE';
    peek_roles_item             CONSTANT VARCHAR2(30)               := 'P910_PEEK_ROLES';
    peek_tree_item              CONSTANT VARCHAR2(30)               := 'P910_TREE_MODE';





    -- ### Introduction
    --
    -- This package is used for rendering navigation menu and for managing Navigation table.
    --





    -- ### Menu item checks and peek functions
    --

    --
    -- Check if page is available to current user
    --
    FUNCTION is_available (
        in_page_id              navigation.page_id%TYPE
    )
    RETURN CHAR;



    --
    -- Check if page is visible to current user (for navigation groups)
    --
    FUNCTION is_visible (
        in_current_page_id      navigation.page_id%TYPE,
        in_requested_page_id    navigation.page_id%TYPE
    )
    RETURN CHAR;



    --
    -- Check if calling role is enabled for peeking
    --
    FUNCTION is_role_peeking_enabled
    RETURN BOOLEAN;



    --
    -- Return page_id from peeking
    --
    FUNCTION get_peeked_page_id
    RETURN navigation.page_id%TYPE;



    --
    -- Convert APEX page_name to rich HTML with icons
    --
    FUNCTION get_page_label (
        in_page_name            apex_application_pages.page_name%TYPE
    )
    RETURN VARCHAR2;





    -- ### Navigation table management
    --

    --
    -- Remove pages from Navigation table if they dont exists as APEX pages
    --
    PROCEDURE remove_missing_pages;



    --
    -- Add pages to Navigation table if they exists as APEX pages
    --
    PROCEDURE add_new_pages;

END;
/
