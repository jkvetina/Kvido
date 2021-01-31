CREATE OR REPLACE PACKAGE nav AS

    auth_package        CONSTANT VARCHAR2(30) := 'AUTH';



    FUNCTION is_available (
        in_page_id      apex_application_pages.page_id%TYPE
    )
    RETURN CHAR;

END;
/
