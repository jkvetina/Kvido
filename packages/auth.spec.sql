CREATE OR REPLACE PACKAGE auth AS

    -- ### Introduction
    --
    -- This package is used for application specific roles
    --



    --
    -- Check if user is a developer
    --
    FUNCTION is_developer
    RETURN CHAR;

END;
/
