CREATE OR REPLACE PACKAGE BODY ctx AS

    FUNCTION get_app_id
    RETURN logs.app_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    END;



    FUNCTION get_page_id
    RETURN logs.page_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_PAGE_ID'));
    END;



    FUNCTION get_user_id
    RETURN logs.user_id%TYPE AS
    BEGIN
        RETURN COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), NULL, USER);
    END;



    PROCEDURE set_user_id (
        in_user_id  logs.user_id%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, ctx.app_user_id, in_user_id);
    END;



    FUNCTION get_session_db
    RETURN logs.session_db%TYPE AS
        out_session     logs.session_db%TYPE;
    BEGIN
        SELECT TO_NUMBER(s.sid || '.' || s.serial#) INTO out_session
        FROM v$session s
        WHERE s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
        --
        RETURN out_session;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_session_apex
    RETURN logs.session_apex%TYPE AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
    END;



    FUNCTION get_context_a
    RETURN logs.context_a%TYPE AS
    BEGIN
        RETURN CASE WHEN ctx.app_context_a IS NOT NULL
            THEN SYS_CONTEXT(ctx.app_namespace, ctx.app_context_a)
            ELSE NULL END;
    END;



    PROCEDURE set_context_a (
        in_value    logs.context_a%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, ctx.app_context_a, in_value);
    END;



    FUNCTION get_context_b
    RETURN logs.context_b%TYPE AS
    BEGIN
        RETURN CASE WHEN ctx.app_context_b IS NOT NULL
            THEN SYS_CONTEXT(ctx.app_namespace, ctx.app_context_b)
            ELSE NULL END;
    END;



    PROCEDURE set_context_b (
        in_value    logs.context_b%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, ctx.app_context_b, in_value);
    END;



    FUNCTION get_context_c
    RETURN logs.context_c%TYPE AS
    BEGIN
        RETURN CASE WHEN ctx.app_context_c IS NOT NULL
            THEN SYS_CONTEXT(ctx.app_namespace, ctx.app_context_c)
            ELSE NULL END;
    END;



    PROCEDURE set_context_c (
        in_value    logs.context_c%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, ctx.app_context_c, in_value);
    END;

END;
/

