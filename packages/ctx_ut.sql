CREATE OR REPLACE PACKAGE BODY ctx_ut AS

    PROCEDURE before_all AS
    BEGIN
        DELETE FROM contexts t;
        COMMIT;
    END;



    PROCEDURE after_all AS
    BEGIN
        ROLLBACK;
    EXCEPTION
    WHEN PROGRAM_ERROR THEN
        NULL;
    END;



    PROCEDURE before_each AS
    BEGIN
        DELETE FROM contexts t;
        COMMIT;
    END;



    PROCEDURE after_each AS
    BEGIN
        ROLLBACK;
    END;



    PROCEDURE set_context AS
        curr_value      contexts.payload%TYPE;
    BEGIN
        ctx.set_user_id();
        --
        FOR c IN (
            SELECT 'TEST' AS name, '1'          AS value FROM DUAL UNION ALL
            SELECT 'TEST' AS name, '3.1415'     AS value FROM DUAL UNION ALL
            SELECT 'TEST' AS name, '3,1415'     AS value FROM DUAL UNION ALL
            SELECT 'TEST' AS name, 'STRING'     AS value FROM DUAL UNION ALL
            SELECT 'TEST' AS name, NULL         AS value FROM DUAL
        ) LOOP
            -- make sure current value is empty
            ctx.set_context(c.name);  -- clear context variable
            --
            curr_value := SYS_CONTEXT(ctx.app_namespace, c.name);
            --
            ut.expect(curr_value).to_be_null();

            -- set new value and verify
            ctx.set_context (
                in_name     => c.name,
                in_value    => c.value
            );
            --
            curr_value := SYS_CONTEXT(ctx.app_namespace, c.name);
            --
            ut.expect(curr_value).to_equal(c.value);
            --
            curr_value := ctx.get_context(c.name);  -- get_context test
            --
            ut.expect(curr_value).to_equal(c.value);
        END LOOP;
    END;



    PROCEDURE set_context#user_id AS
        exp_user_id     contexts.user_id%TYPE := 'TEST_USER';
        curr_user_id    contexts.user_id%TYPE;
        new_user_id     contexts.user_id%TYPE := 'ANOTHER_USER';
    BEGIN
        -- make sure we have set some user
        ctx.set_user_id(exp_user_id);
        curr_user_id := ctx.get_user_id();
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);  -- get_user_id test

        -- try to change user_id thru regular set_context
        BEGIN
            ctx.set_context (
                in_name     => ctx.app_user_attr,
                in_value    => new_user_id
            );
            ut.fail('NO_EXCEPTION_RAISED');
        EXCEPTION
        WHEN OTHERS THEN
            -- exception expected
            IF SQLCODE != -20000 THEN
                ut.fail('WRONG_EXCEPTION_RAISED');
            END IF;
        END;

        -- check that user_id was not modified
        curr_user_id := SYS_CONTEXT(ctx.app_namespace, ctx.app_user_attr);
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);
    END;



    PROCEDURE get_context_date AS
        exp_date        CONSTANT DATE   := TRUNC(SYSDATE) + 19/24 + 32/1440 + 58/86400;  -- 19:32:58
        curr_date       DATE;
        curr_string     VARCHAR2(30);
    BEGIN
        ctx.set_context('DATE', exp_date);
        --
        curr_date   := ctx.get_context_date('DATE');
        curr_string := ctx.get_context('DATE');
        --
        ut.expect(curr_date).to_equal(exp_date);
        --
        ut.expect(TO_CHAR(curr_date, 'YYYY-MM-DD HH24:MI:SS')).to_equal(TO_CHAR(exp_date, 'YYYY-MM-DD HH24:MI:SS'));
        --
        ut.expect(curr_string).to_equal(TO_CHAR(exp_date, ctx.format_date_time));
    END;



    PROCEDURE get_context_date#wrong_format AS
        curr_date       DATE;
    BEGIN
        ctx.set_context('DATE', 'NOT A VALID DATE');
        --
        curr_date := ctx.get_context_date('DATE');  -- throws ORA-20000
    END;



    PROCEDURE set_user_id AS
        exp_user_id     contexts.user_id%TYPE := 'TEST_USER';
        exp_payload     contexts.payload%TYPE;
        curr            contexts%ROWTYPE;
        count_contexts  PLS_INTEGER;
    BEGIN
        ctx.set_user_id();

        -- check number of contexts, zero is expected
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace       = ctx.app_namespace
            AND s.attribute     != ctx.app_user_attr;
        --
        ut.expect(count_contexts).to_equal(0);

        -- set user and overwrite payload
        exp_payload :=
            'NAME' || ctx.splitter_values || 'VALUE' || ctx.splitter_rows ||
            'NAME2' || ctx.splitter_values || 'VALUE2';
        --
        ctx.set_user_id (
            in_user_id  => exp_user_id,
            in_payload  => exp_payload
        );
        --
        ut.expect(exp_payload).to_equal(ctx.get_payload());
        ctx.save_contexts();

        -- check that contexts record exists
        SELECT x.* INTO curr
        FROM contexts x
        WHERE x.user_id         = exp_user_id
            AND x.updated_at    >= SYSDATE - 1/86400;
        --
        ut.expect(curr.payload).to_equal(exp_payload);

        -- test payload recovery
        ctx.set_user_id (
            in_user_id  => exp_user_id      -- recover previous values
        );
        --
        ut.expect(exp_payload).to_equal(ctx.get_payload());
        --
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace       = ctx.app_namespace
            AND s.attribute     != ctx.app_user_attr;
        --
        ut.expect(count_contexts).to_be_greater_than(0);

        -- set user and empty payload
        ctx.set_user_id (
            in_user_id  => exp_user_id,
            in_payload  => ''           -- clear existing values
        );
        --
        ut.expect(ctx.get_payload()).to_be_null();
        --
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace       = ctx.app_namespace
            AND s.attribute     != ctx.app_user_attr;
        --
        ut.expect(count_contexts).to_equal(0);
    END;



    PROCEDURE save_contexts AS
        curr_user_id    CONSTANT contexts.user_id%TYPE  := 'TESTER__';
        --curr_app_id     CONSTANT contexts.app_id%TYPE   := 0;
        --
        test_string     CONSTANT VARCHAR2(30)   := 'TODAY';
        test_number     CONSTANT VARCHAR2(30)   := 3.1415;
        test_date       CONSTANT DATE           := SYSDATE;
        test_extra      CONSTANT VARCHAR2(30)   := 'EXTRA';
        --
        curr_payload    contexts.payload%TYPE;
        curr_timestamp  contexts.updated_at%TYPE;
        upd_payload     contexts.payload%TYPE;
        upd_timestamp   contexts.updated_at%TYPE;
        exp_payload     contexts.payload%TYPE;
    BEGIN
        -- clear contexts and set user
        ctx.set_user_id(curr_user_id);

        -- set some contexts
        ctx.set_context('STRING',   test_string);
        ctx.set_context('NUMBER',   test_number);
        ctx.set_context('DATE',     test_date);

        -- test insert
        ctx.save_contexts();
        --
        exp_payload := ctx.get_payload();
        --
        SELECT x.payload, x.updated_at
        INTO curr_payload, curr_timestamp
        FROM contexts x
        WHERE x.user_id         = curr_user_id
            AND x.updated_at    >= SYSDATE - 1/86400;
        --
        ut.expect(curr_payload).to_equal(exp_payload);

        -- alter contexts
        ctx.set_context('DATE',     test_date + 1/24);  -- change existing context
        ctx.set_context('EXTRA',    test_extra);        -- add one more
        --
        DBMS_SESSION.SLEEP(1);

        -- test update
        ctx.save_contexts();
        --
        SELECT t.payload, t.updated_at
        INTO upd_payload, upd_timestamp
        FROM contexts t
        WHERE t.user_id = curr_user_id;
        --
        ut.expect(upd_payload).to_equal(ctx.get_payload());
        --
        ut.expect(upd_timestamp).to_be_greater_than(curr_timestamp);    -- check timestamp
        --
        curr_payload := ctx.get_payload();
        --
        ut.expect(curr_payload).not_to_equal(exp_payload);
        --
        ut.expect(curr_payload).to_equal(upd_payload);

        -- check session_db
        --
        -- @TODO:
        --
    END;



    PROCEDURE load_contexts AS
        curr_user_id    CONSTANT contexts.user_id%TYPE  := 'TESTER__';
        --curr_app_id     CONSTANT contexts.app_id%TYPE   := 0;
        --
        test_string     CONSTANT VARCHAR2(30)   := 'TODAY';
        test_number     CONSTANT VARCHAR2(30)   := 3.1415;
        test_date       CONSTANT DATE           := SYSDATE;
        test_extra      CONSTANT VARCHAR2(30)   := 'EXTRA';
        --
        count_contexts  PLS_INTEGER;
        r_expected      SYS_REFCURSOR;
        r_current       SYS_REFCURSOR;
    BEGIN
        -- clear contexts and set user
        ctx.set_user_id(curr_user_id);

        -- set some contexts
        ctx.set_context('STRING',   test_string);
        ctx.set_context('NUMBER',   test_number);
        ctx.set_context('DATE',     test_date);

        -- update table
        ctx.save_contexts();

        -- clear current contexts
        ctx.set_user_id();

        -- check number of contexts, zero is expected
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace = ctx.app_namespace;
        --
        ut.expect(count_contexts).to_equal(0);

        -- load contexts for current user
        ctx.load_contexts (
            in_user_id => curr_user_id
        );

        -- check contexts
        OPEN r_expected FOR
            SELECT 'STRING' AS name,    test_string                                 AS value FROM DUAL UNION ALL
            SELECT 'NUMBER' AS name,    TO_CHAR(test_number)                        AS value FROM DUAL UNION ALL
            SELECT 'DATE'   AS name,    TO_CHAR(test_date, ctx.format_date_time)    AS value FROM DUAL
            ORDER BY 1;
        --
        OPEN r_current FOR
            SELECT s.attribute AS name, s.value
            FROM session_context s
            WHERE s.namespace       = ctx.app_namespace
                AND s.attribute     != ctx.app_user_attr            -- user_id has dedicated column
                AND s.attribute     NOT LIKE '%\_\_' ESCAPE '\'     -- ignore private contexts
            ORDER BY 1;
        --
        ut.expect(r_current).to_equal(r_expected);
    END;



    PROCEDURE init AS
        old_value       contexts.payload%TYPE;
        new_value       contexts.payload%TYPE;
        --
        exp_user_id     contexts.user_id%TYPE := 'TEST_USER';
        curr_user_id    contexts.user_id%TYPE;
        --
        count_contexts  PLS_INTEGER;
        r_expected      SYS_REFCURSOR;
        r_current       SYS_REFCURSOR;
    BEGIN
        -- set any context for negative test
        ctx.set_context('NEGATIVE_TEST', 'TRUE');
        ctx.set_user_id();

        -- check client identifier
        -- check app info module and action
        OPEN r_expected FOR
            SELECT
                NULL AS client_id,
                NULL AS module_name,
                NULL AS action_name
            FROM DUAL;
        --
        OPEN r_current FOR
            SELECT
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') AS client_id,
                SYS_CONTEXT('USERENV', 'MODULE')            AS module_name,
                SYS_CONTEXT('USERENV', 'ACTION')            AS action_name
            FROM DUAL;
        --
        ut.expect(r_current).to_equal(r_expected);

        -- check number of contexts, zero is expected
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace = ctx.app_namespace;
        --
        ut.expect(count_contexts).to_equal(0);

        -- check user_id if passed
        ctx.set_user_id(exp_user_id);
        --
        curr_user_id := ctx.get_user_id();
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);

        -- check client identifier
        -- check app info module and action
        OPEN r_expected FOR
            SELECT
                exp_user_id         AS client_id,
                'CTX.SET_USER_ID'   AS module_name,     -- the most recent log_module
                'LOG_USERENV'       AS action_name      -- the most recent action
            FROM DUAL;
        --
        OPEN r_current FOR
            SELECT
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') AS client_id,
                SYS_CONTEXT('USERENV', 'MODULE')            AS module_name,
                SYS_CONTEXT('USERENV', 'ACTION')            AS action_name
            FROM DUAL;
        --
        ut.expect(r_current).to_equal(r_expected);
    END;



    PROCEDURE set_directly AS
    BEGIN
        DBMS_SESSION.SET_CONTEXT (
            namespace    => ctx.app_namespace,
            attribute    => 'DIRECT_SET_MUST_FAIL',
            value        => 'TRUE'
        );
        --
        ut.fail('ERR_EXPECTED');  -- ORA-01031
    END;

END;
/
