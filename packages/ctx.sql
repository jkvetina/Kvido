CREATE OR REPLACE PACKAGE BODY ctx AS

    recent_session_db       debug_log.session_db%TYPE;      -- to save resources



    PROCEDURE init (
        in_user_id      debug_log.user_id%TYPE := NULL
    ) AS
        new_user_id     CONSTANT debug_log.user_id%TYPE := NVL(in_user_id, ctx.get_user_id());
    BEGIN
        bug.log_module(new_user_id);
        --
        DBMS_SESSION.CLEAR_ALL_CONTEXT(ctx.app_namespace);
        DBMS_SESSION.CLEAR_IDENTIFIER();
        --
        DBMS_APPLICATION_INFO.SET_MODULE (
            module_name => NULL,
            action_name => NULL
        );
        --
        ctx.set_user_id(new_user_id);
    END;



    FUNCTION get_app_id
    RETURN debug_log.app_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    END;



    FUNCTION get_page_id
    RETURN debug_log.page_id%TYPE AS
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            RETURN NV('APP_PAGE_ID');
        $ELSE
            RETURN NULL;
        $END    
    END;



    FUNCTION get_user_id
    RETURN debug_log.user_id%TYPE AS
    BEGIN
        RETURN COALESCE(
            SYS_CONTEXT(ctx.app_namespace, ctx.app_user_id),
            SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
            USER
        );
    END;



    PROCEDURE set_user_id (
        in_user_id  debug_log.user_id%TYPE
    ) AS
    BEGIN
        bug.log_module(in_user_id);
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace    => ctx.app_namespace,
            attribute    => ctx.app_user_id,
            value        => in_user_id,
            username     => in_user_id,
            client_id    => ctx.get_client_id(in_user_id)
        );
    END;



    FUNCTION get_session_db
    RETURN debug_log.session_db%TYPE AS
    BEGIN
        IF recent_session_db IS NULL THEN
            SELECT TO_NUMBER(s.sid || '.' || s.serial#) INTO recent_session_db
            FROM v$session s
            WHERE s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
        END IF;
        --
        RETURN recent_session_db;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_session_apex
    RETURN debug_log.session_apex%TYPE AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
    END;



    FUNCTION get_client_id (
        in_user_id      contexts.user_id%TYPE := NULL
    )
    RETURN VARCHAR2 AS
    BEGIN
        RETURN
            NVL(in_user_id, ctx.get_user_id()) || ':' ||
            NVL(ctx.get_session_apex(), SYS_CONTEXT('USERENV', 'SESSIONID'));
    END;



    FUNCTION get_context (
        in_name     VARCHAR2,
        in_format   VARCHAR2    := NULL,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN VARCHAR2 AS
    BEGIN
        IF in_format IS NOT NULL THEN
            RETURN TO_CHAR(ctx.get_context_date(in_name), in_format);
        END IF;
        --
        RETURN SYS_CONTEXT(ctx.app_namespace, in_name);
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE;
        END IF;
        --
        RETURN NULL;
    END;



    FUNCTION get_context_number (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN NUMBER AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT(ctx.app_namespace, in_name));
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE;
        END IF;
        --
        RETURN NULL;
    END;



    FUNCTION get_context_date (
        in_name     VARCHAR2,
        in_raise    VARCHAR2    := 'Y'  -- boolean for SQL
    )
    RETURN DATE AS
    BEGIN
        RETURN TO_DATE(SYS_CONTEXT(ctx.app_namespace, in_name), 'YYYY-MM-DD HH24:MI:SS');
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE;
        END IF;
        --
        RETURN NULL;
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    VARCHAR2
    ) AS
    BEGIN
        IF in_name = ctx.app_user_id OR in_name IS NULL THEN
            RETURN;  -- cant update this directly
        END IF;
        --
        IF in_value IS NULL THEN
            DBMS_SESSION.CLEAR_CONTEXT (
                namespace           => ctx.app_namespace,
                --client_identifier   => ctx.get_client_id(),
                attribute           => in_name
            );
            RETURN;
        END IF;
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace    => ctx.app_namespace,
            attribute    => in_name,
            value        => in_value,
            username     => ctx.get_user_id(),
            client_id    => ctx.get_client_id()
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'SET_CTX_FAILED');
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    DATE
    ) AS
        str_value   VARCHAR2(30);
    BEGIN
        str_value := TO_CHAR(in_value, format_date);
        --
        ctx.set_context (
            in_name     => in_name,
            in_value    => str_value
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000, 'SET_CTX_DATE_FAILED', TRUE);
    END;



    PROCEDURE load_contexts (
        in_app_id           contexts.app_id%TYPE        := NULL,
        in_user_id          contexts.user_id%TYPE       := NULL,
        in_session_db       contexts.session_db%TYPE    := NULL,
        in_session_apex     contexts.session_apex%TYPE  := NULL
    ) AS
        rec                 contexts%ROWTYPE;
    BEGIN
        rec.app_id          := COALESCE(in_app_id,          ctx.get_app_id(),       0);
        rec.user_id         := COALESCE(in_user_id,         ctx.get_user_id());
        rec.session_apex    := COALESCE(in_session_apex,    ctx.get_session_apex(), 0);
        rec.session_db      := COALESCE(in_session_db,      ctx.get_session_db(),   0);
        --
        bug.log_module(rec.app_id, rec.user_id, rec.session_db, rec.session_apex);

        -- retrieve latest payload
        BEGIN
            -- find exact match first
            SELECT x.payload INTO rec.payload
            FROM contexts x
            WHERE x.app_id          = rec.app_id
                AND x.user_id       = rec.user_id
                AND x.session_apex  = rec.session_apex
                AND x.session_db    = rec.session_db;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                -- find latest session
                SELECT x.payload INTO rec.payload
                FROM (
                    SELECT x.payload
                    FROM contexts x
                    WHERE x.app_id      = rec.app_id
                        AND x.user_id   = rec.user_id
                    ORDER BY x.updated_at
                ) x
                WHERE ROWNUM = 1;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN;  -- no session available, no need to continue
            END;
        END;

        -- parse payload to SYS_CONTEXT and set user
        ctx.apply_payload(rec.payload);
        ctx.set_user_id(in_user_id);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    END;



    PROCEDURE apply_payload (
        in_payload          contexts.payload%TYPE
    ) AS
    BEGIN
        bug.log_module();
        --
        IF in_payload IS NULL THEN
            RETURN;
        END IF;

        -- parse payload and store it in SYS_CONTEXT
        FOR c IN (
            WITH r AS (
                SELECT REGEXP_SUBSTR(in_payload, '[^' || ctx.splitter_rows || ']+', 1, LEVEL) AS row_
                FROM DUAL
                CONNECT BY LEVEL <= REGEXP_COUNT(in_payload, '[' || ctx.splitter_rows || ']')
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



    PROCEDURE save_contexts
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 contexts%ROWTYPE;
    BEGIN
        rec.app_id          := NVL(ctx.get_app_id(), 0);
        rec.user_id         := ctx.get_user_id();
        rec.session_apex    := NVL(ctx.get_session_apex(),  0);
        rec.session_db      := NVL(ctx.get_session_db(),    0);
        rec.payload         := ctx.get_payload();
        rec.updated_at      := SYSTIMESTAMP;
        --
        bug.log_module(rec.user_id, rec.session_apex, rec.session_db);
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



    FUNCTION get_payload
    RETURN contexts.payload%TYPE
    AS
        payload         contexts.payload%TYPE;
    BEGIN
        FOR c IN (
            SELECT s.attribute, s.value
            FROM session_context s
            WHERE s.namespace   = ctx.app_namespace
                AND s.attribute != ctx.app_user_id      -- user_id has dedicated column
                AND s.value     IS NOT NULL
            ORDER BY 1
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
