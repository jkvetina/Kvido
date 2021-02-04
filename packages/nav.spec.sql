CREATE OR REPLACE PACKAGE nav AS

    auth_package                CONSTANT VARCHAR2(30)       := 'AUTH';



    FUNCTION is_available (
        in_page_id              navigation.page_id%TYPE
    )
    RETURN CHAR;



    FUNCTION is_visible (
        in_current_page_id      navigation.page_id%TYPE,
        in_requested_page_id    navigation.page_id%TYPE
    )
    RETURN CHAR;



    PROCEDURE remove_missing_pages;



    PROCEDURE add_new_pages;



    FUNCTION get_page_label (
        in_page_name            apex_application_pages.page_name%TYPE
    )
    RETURN VARCHAR2;

END;
/
