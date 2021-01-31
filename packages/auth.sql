CREATE OR REPLACE PACKAGE BODY auth AS

    FUNCTION is_developer
    RETURN CHAR AS
        PRAGMA UDF;
    BEGIN
        RETURN CASE WHEN apex.is_developer() THEN 'Y' ELSE 'N' END;
    END;

END;
/
