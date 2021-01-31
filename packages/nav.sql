CREATE OR REPLACE PACKAGE BODY nav AS

    FUNCTION is_available (
        in_page_id      apex_application_pages.page_id%TYPE
    )
    RETURN CHAR
    AS
        proc_name       user_procedures.procedure_name%TYPE;
        proc_result     CHAR;
        --
        PRAGMA UDF;     -- SQL only
    BEGIN
        SELECT s.object_name || '.' || s.procedure_name INTO proc_name
        FROM apex_application_pages p
        JOIN user_procedures s
            ON s.object_name                = nav.auth_package
            AND s.procedure_name            = p.authorization_scheme
        WHERE p.application_id              = sess.get_app_id()
            AND p.page_id                   = in_page_id
            AND p.authorization_scheme      IS NOT NULL;
        --
        EXECUTE IMMEDIATE
            'BEGIN :r := ' || proc_name || '; END;'
            USING OUT proc_result;
        --
        RETURN NVL(proc_result, 'N');
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;

END;
/
