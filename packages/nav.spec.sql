CREATE OR REPLACE PACKAGE nav AS

    auth_package        CONSTANT VARCHAR2(30) := 'AUTH';



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

END;
/
