CREATE OR REPLACE PACKAGE apex AS

    /**
     * This package is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     */



    PROCEDURE set_item (
        in_name         VARCHAR2,
        in_value        VARCHAR2
    );



    FUNCTION get_item (
        in_name         VARCHAR2
    )
    RETURN VARCHAR2;



    PROCEDURE clear_items (
        in_items        VARCHAR2 := NULL
        --
        -- NULL = all except passed in args
        -- %    = all
        -- list = only items on list
        --
    );



    PROCEDURE redirect (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    );



    FUNCTION get_page_link (
        in_page_id      NUMBER      := NULL,
        in_names        VARCHAR2    := NULL,
        in_values       VARCHAR2    := NULL
    )
    RETURN VARCHAR2;

END;
/
