CREATE OR REPLACE PACKAGE BODY auth AS

    --
    -- Check if current user id APEX developer, returns Y/N
    --
    FUNCTION is_developer
    RETURN CHAR;

END;
/
