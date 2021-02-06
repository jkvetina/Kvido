CREATE OR REPLACE PACKAGE app AS

    FUNCTION manipulate_page_label (
        in_page_name VARCHAR2
    )
    RETURN VARCHAR2;

END;
/
