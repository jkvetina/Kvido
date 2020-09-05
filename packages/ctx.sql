CREATE OR REPLACE PACKAGE BODY ctx AS

    recent_session_db       logs.session_db%TYPE;      -- to save resources



    PROCEDURE init__
    ACCESSIBLE BY (
        PACKAGE ctx,
        PACKAGE ctx_ut
    ) AS
    BEGIN
        DBMS_SESSION.CLEAR_ALL_CONTEXT(ctx.app_namespace);
        DBMS_SESSION.CLEAR_IDENTIFIER();
        --
        DBMS_APPLICATION_INFO.SET_MODULE (
            module_name => NULL,
            action_name => NULL
        );
    END;



    PROCEDURE set_user_id (
        in_user_id          logs.user_id%TYPE       := NULL
    ) AS
    BEGIN
        ctx.init__();

        -- load contexts from previous session
        IF in_user_id IS NOT NULL THEN
            ctx.load_contexts (
                in_user_id          => in_user_id,
                in_app_id           => ctx.get_app_id(),
                in_session_db       => ctx.get_session_db(),
                in_session_apex     => ctx.get_session_apex()
            );
            --
            ctx.set_user_id (
                in_user_id  => in_user_id,
                in_payload  => ctx.get_payload()
            );
        END IF;
    END;



    PROCEDURE set_user_id (
        in_user_id          logs.user_id%TYPE,
        in_payload          contexts.payload%TYPE
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 contexts%ROWTYPE;
        old_sess_db         contexts.session_db%TYPE;
        old_sess_apex       contexts.session_apex%TYPE;
    BEGIN
        bug.log_module(in_user_id, LENGTH(in_payload));
        --
        ctx.init__();

        -- set session things
        DBMS_SESSION.SET_IDENTIFIER(in_user_id);                -- USERENV.CLIENT_IDENTIFIER
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(in_user_id);      -- CLIENT_INFO, v$
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace   => ctx.app_namespace,
            attribute   => ctx.app_user_attr,
            value       => in_user_id,
            username    => in_user_id,
            client_id   => ctx.get_client_id(in_user_id)
        );

        -- prepare record
        rec.app_id          := NVL(ctx.get_app_id(), 0);
        rec.user_id         := in_user_id;
        rec.session_db      := NVL(ctx.get_session_db(),    0);
        rec.session_apex    := NVL(ctx.get_session_apex(),  0);
        rec.updated_at      := SYSDATE;

        -- load contexts
        IF in_payload IS NOT NULL THEN
            ctx.apply_payload(in_payload);
            rec.payload := in_payload;
        END IF;

        -- store new values
        UPDATE contexts x
        SET x.payload           = rec.payload,
            x.updated_at        = rec.updated_at
        WHERE x.app_id          = rec.app_id
            AND x.user_id       = rec.user_id
            AND x.session_db    = rec.session_db
            AND x.session_apex  = rec.session_apex;
        --
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO contexts VALUES rec;
            COMMIT;
            --
            bug.log_userenv();
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SET_USER_ID_FAILED', TRUE);
    END;



    FUNCTION get_app_id
    RETURN logs.app_id%TYPE AS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('APEX$SESSION', 'APP_ID'));
    END;



    FUNCTION get_page_id
    RETURN logs.page_id%TYPE AS
    BEGIN
        $IF $$APEX_INSTALLED $THEN
            RETURN NV('APP_PAGE_ID');
        $ELSE
            RETURN NULL;
        $END    
    END;



    FUNCTION get_user_id
    RETURN logs.user_id%TYPE AS
    BEGIN
        RETURN COALESCE(
            SYS_CONTEXT(ctx.app_namespace, ctx.app_user_attr),
            SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
            ctx.app_user
        );
    END;



    FUNCTION get_session_db
    RETURN logs.session_db%TYPE AS
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
    RETURN logs.session_apex%TYPE AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
    END;



    FUNCTION get_client_id (
        in_user_id          contexts.user_id%TYPE := NULL
    )
    RETURN VARCHAR2 AS      -- mimic APEX client_id
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
            RETURN TO_CHAR(ctx.get_context_date(UPPER(in_name)), in_format);
        END IF;
        --
        RETURN SYS_CONTEXT(ctx.app_namespace, UPPER(in_name));
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(bug.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
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
        RETURN TO_NUMBER(SYS_CONTEXT(ctx.app_namespace, UPPER(in_name)));
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(bug.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
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
        RETURN TO_DATE(SYS_CONTEXT(ctx.app_namespace, UPPER(in_name)), ctx.format_date_time);
    EXCEPTION
    WHEN OTHERS THEN
        IF in_raise = 'Y' THEN
            RAISE_APPLICATION_ERROR(bug.app_exception_code, 'GET_CONTEXT_FAILED', TRUE);
        END IF;
        --
        RETURN NULL;
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    VARCHAR2        := NULL
    ) AS
    BEGIN
        IF in_name LIKE '%\_\_' ESCAPE '\' OR in_name IS NULL THEN
            RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SET_CTX_FORBIDDEN', TRUE);
        END IF;
        --
        IF in_value IS NULL THEN
            DBMS_SESSION.CLEAR_CONTEXT (
                namespace           => ctx.app_namespace,
                --client_identifier   => ctx.get_client_id(),
                attribute           => UPPER(in_name)
            );
            RETURN;
        END IF;
        --
        DBMS_SESSION.SET_CONTEXT (
            namespace    => ctx.app_namespace,
            attribute    => UPPER(in_name),
            value        => in_value,
            username     => ctx.get_user_id(),
            client_id    => ctx.get_client_id()
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SET_CTX_FAILED', TRUE);
    END;



    PROCEDURE set_context (
        in_name     VARCHAR2,
        in_value    DATE
    ) AS
        str_value   VARCHAR2(30);
    BEGIN
        str_value := TO_CHAR(in_value, ctx.format_date_time);
        --
        ctx.set_context (
            in_name     => in_name,
            in_value    => str_value
        );
    EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SET_CTX_DATE_FAILED', TRUE);
    END;



    PROCEDURE apply_payload (
        in_payload          contexts.payload%TYPE
    ) AS
        payload_item        contexts.payload%TYPE;
        payload_name        contexts.payload%TYPE;
        payload_value       contexts.payload%TYPE;
    BEGIN
        IF in_payload IS NULL THEN
            RETURN;
        END IF;
        --
        FOR i IN 1 .. REGEXP_COUNT(in_payload, '[' || ctx.splitter_rows || ']') + 1 LOOP
            payload_item    := REGEXP_SUBSTR(in_payload, '[^' || ctx.splitter_rows || ']+', 1, i);
            payload_name    := RTRIM(SUBSTR(payload_item, 1, INSTR(payload_item, ctx.splitter_values) - 1));
            payload_value   := SUBSTR(payload_item, INSTR(payload_item, ctx.splitter_values) + 1);
            --
            IF payload_name IS NOT NULL THEN
                ctx.set_context (
                    in_name     => payload_name,
                    in_value    => payload_value
                );
            END IF;
        END LOOP;
    END;



    PROCEDURE load_contexts (
        in_user_id          contexts.user_id%TYPE       := NULL,
        in_app_id           contexts.app_id%TYPE        := NULL,
        in_session_db       contexts.session_db%TYPE    := NULL,
        in_session_apex     contexts.session_apex%TYPE  := NULL
    ) AS
        rec                 contexts%ROWTYPE;
    BEGIN
        rec.app_id          := COALESCE(in_app_id,          ctx.get_app_id(),       0);
        rec.user_id         := COALESCE(in_user_id,         ctx.get_user_id());
        rec.session_db      := COALESCE(in_session_db,      ctx.get_session_db(),   0);
        rec.session_apex    := COALESCE(in_session_apex,    ctx.get_session_apex(), 0);
        --
        bug.log_module(rec.app_id, rec.user_id, rec.session_db, rec.session_apex);

        -- find best session
        BEGIN
            -- try exact match first
            SELECT x.payload INTO rec.payload
            FROM contexts x
            WHERE x.app_id          = rec.app_id
                AND x.user_id       = rec.user_id
                AND x.session_db    = rec.session_db
                AND x.session_apex  = rec.session_apex;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- try partial match and use latest session
            SELECT MIN(x.payload) KEEP (DENSE_RANK FIRST
                ORDER BY CASE
                        WHEN x.session_apex = rec.session_apex  THEN 1
                        WHEN x.session_db   = rec.session_db    THEN 2
                        END NULLS LAST,
                    x.updated_at DESC
                )
            INTO rec.payload
            FROM contexts x
            WHERE x.app_id          = rec.app_id
                AND x.user_id       = rec.user_id;
        END;
        --
        IF rec.payload IS NOT NULL THEN
            ctx.apply_payload(rec.payload);
        END IF;
    END;



    PROCEDURE save_contexts
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 contexts%ROWTYPE;
    BEGIN
        rec.app_id          := NVL(ctx.get_app_id(), 0);
        rec.user_id         := ctx.get_user_id();

        -- dont store contexts for generic user
        IF rec.user_id = ctx.app_user THEN
            bug.log_module(rec.app_id, rec.user_id);
            --
            RAISE NO_DATA_FOUND;
        END IF;

        rec.session_db      := NVL(ctx.get_session_db(),    0);
        rec.session_apex    := NVL(ctx.get_session_apex(),  0);
        rec.payload         := ctx.get_payload();
        rec.updated_at      := SYSDATE;
        --
        bug.log_module(rec.app_id, rec.user_id, rec.session_db, rec.session_apex);

        -- store new values
        UPDATE contexts x
        SET x.payload           = rec.payload,
            x.updated_at        = rec.updated_at
        WHERE x.app_id          = rec.app_id
            AND x.user_id       = rec.user_id
            AND x.session_db    = rec.session_db
            AND x.session_apex  = rec.session_apex;
        --
        IF SQL%ROWCOUNT = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SAVE_CONTEXTS_FAILED', TRUE);
    END;



    PROCEDURE save_contexts (
        in_log_id           logs.log_id%TYPE
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        bug.log_module(in_log_id);

        -- store new values
        UPDATE logs e
        SET e.contexts  = ctx.get_payload(),
            e.user_id   = ctx.get_user_id()
        WHERE e.log_id  = in_log_id;
        --
        IF SQL%ROWCOUNT = 0 THEN
            RAISE NO_DATA_FOUND;
        END IF;
        --
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(bug.app_exception_code, 'SAVE_CONTEXTS_FAILED', TRUE);
    END;



    FUNCTION get_payload
    RETURN contexts.payload%TYPE
    AS
        out_payload     contexts.payload%TYPE;
    BEGIN
        SELECT
            LISTAGG(s.attribute || ctx.splitter_values || s.value, ctx.splitter_rows)
                WITHIN GROUP (ORDER BY s.attribute)
        INTO out_payload
        FROM session_context s
        WHERE s.namespace       = ctx.app_namespace
            AND s.attribute     != ctx.app_user_attr            -- user_id has dedicated column
            AND s.attribute     NOT LIKE '%\_\_' ESCAPE '\'     -- ignore private contexts
            AND s.value         IS NOT NULL;
        --
        RETURN out_payload;
    END;

END;
/
