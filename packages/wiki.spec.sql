CREATE OR REPLACE PACKAGE wiki AS

    PROCEDURE desc_table (
        in_name VARCHAR2
    );



    PROCEDURE desc_view (
        in_name     VARCHAR2
    );



    PROCEDURE desc_spec (
        in_name         VARCHAR2,
        in_type         VARCHAR2    := NULL,
        in_overload     NUMBER      := 1
    );



    PROCEDURE desc_body (
        in_name         VARCHAR2,
        in_type         VARCHAR2    := NULL,
        in_overload     NUMBER      := 1
    );



    PROCEDURE desc_package (
        in_package      VARCHAR2
    );

END;
/

