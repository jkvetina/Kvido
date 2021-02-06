CREATE OR REPLACE PACKAGE BODY auth AS

    FUNCTION is_developer
    RETURN CHAR AS
        PRAGMA UDF;
    BEGIN
        -- respect settings in peek_roles_item even for this role
        IF apex.is_developer() AND sess.get_page_id() = nav.peek_page_id THEN
            RETURN CASE WHEN (NVL(INSTR(
                ':' || apex.get_item(nav.peek_roles_item) || ':',
                ':' || 'IS_DEVELOPER' || ':'
                ), 0) > 0)
                THEN 'Y' ELSE 'N' END;
        END IF;
        --
        RETURN CASE WHEN apex.is_developer() THEN 'Y' ELSE 'N' END;
    END;

END;
/
