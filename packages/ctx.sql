CREATE OR REPLACE PACKAGE BODY ctx AS

    FUNCTION get_app_id
    RETURN debug_log.app_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    END;



    FUNCTION get_page_id
    RETURN debug_log.page_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_PAGE_ID'));
    END;



    FUNCTION get_user_id
    RETURN debug_log.user_id%TYPE AS
    BEGIN
        RETURN COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), NULL, USER);
    END;



    PROCEDURE set_user_id (
        in_user_id  debug_log.user_id%TYPE
    ) AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, ctx.app_user_id, in_user_id);
    END;



    FUNCTION get_session_db
    RETURN debug_log.session_db%TYPE AS
        out_session     debug_log.session_db%TYPE;
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
    RETURN debug_log.session_apex%TYPE AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
    END;



    FUNCTION get_context (
        in_name     VARCHAR2
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN SYS_CONTEXT(ctx.app_namespace, in_name);
    END;



    FUNCTION get_context_number (
        in_name     VARCHAR2
    )
    RETURN NUMBER AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT(ctx.app_namespace, in_name));
    END;



    FUNCTION get_context_date (
        in_name     VARCHAR2
    )
    RETURN DATE AS
    BEGIN
        RETURN TO_DATE(SYS_CONTEXT(ctx.app_namespace, in_name), 'YYYY-MM-DD');
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    VARCHAR2
    ) AS
    BEGIN
        IF in_name = ctx.app_user_id THEN
            RETURN;  -- cant update this directly
        END IF;
        --
        DBMS_SESSION.SET_CONTEXT(ctx.app_namespace, in_name, in_value);
    END;



    PROCEDURE load_contexts (
        in_user_id          contexts.user_id%TYPE       := NULL,
        in_session_db       contexts.session_db%TYPE    := NULL,
        in_session_apex     contexts.session_apex%TYPE  := NULL
    ) AS
    BEGIN
        FOR c IN (
            WITH x AS (
                SELECT x.payload
                FROM contexts x
                WHERE x.user_id         = NVL(in_user_id,       ctx.get_user_id())
                    AND x.session_apex  = NVL(in_session_apex,  NVL(ctx.get_session_apex(), 0))
                    AND x.session_db    = NVL(in_session_db,    NVL(ctx.get_session_db(),   0))
            ),
            r AS (
                SELECT REGEXP_SUBSTR(x.payload, '[^' || ctx.splitter_rows || ']+', 1, LEVEL) AS row_
                FROM x
                CONNECT BY LEVEL <= REGEXP_COUNT(x.payload, '[' || ctx.splitter_rows || ']')
            )
            SELECT
                SUBSTR(r.row_, 1, INSTR(r.row_, ctx.splitter_values) - 1)   AS attribute,
                SUBSTR(r.row_, INSTR(r.row_, ctx.splitter_values) + 1)      AS value
            FROM r
        ) LOOP
            ctx.set_context (
                in_name     => c.attribute,
                in_value    => c.value
            );
        END LOOP;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    END;



    PROCEDURE update_contexts
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 contexts%ROWTYPE;
    BEGIN
        rec.user_id         := ctx.get_user_id();
        rec.session_apex    := NVL(ctx.get_session_apex(),  0);
        rec.session_db      := NVL(ctx.get_session_db(),    0);
        rec.payload         := ctx.get_payload();
        rec.updated_at      := SYSTIMESTAMP;
        --
        UPDATE contexts SET ROW = rec;
        --
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO contexts VALUES rec;
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END;



    PROCEDURE clear_contexts AS
    BEGIN
        DBMS_SESSION.CLEAR_ALL_CONTEXT(ctx.app_namespace);
    END;



    FUNCTION get_payload
    RETURN contexts.payload%TYPE
    AS
        payload         contexts.payload%TYPE;
    BEGIN
        FOR c IN (
            SELECT s.attribute, s.value
            FROM session_context s
            WHERE s.namespace   = ctx.app_namespace
                AND s.value     IS NOT NULL
        ) LOOP
            payload := payload ||
                c.attribute || ctx.splitter_values ||
                c.value     || ctx.splitter_rows;
        END LOOP;
        --
        RETURN payload;
    END;

END;
/

