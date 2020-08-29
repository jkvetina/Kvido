CREATE OR REPLACE PACKAGE BODY bug_ut AS

    PROCEDURE before_all AS
    BEGIN
        -- clear log
        DELETE FROM debug_log;
        COMMIT;

        -- clear log setup
        DELETE FROM debug_log_setup
        WHERE user_id = ctx.get_user_id();
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
        -- clear log
        DELETE FROM debug_log;
        COMMIT;
    END;



    PROCEDURE after_each AS
    BEGIN
        ROLLBACK;
    END;



    PROCEDURE raise_error AS
        first_record        debug_log%ROWTYPE;
        exp_module_name     CONSTANT debug_log.module_name%TYPE := $$PLSQL_UNIT || '.RAISE_ERROR';
        exp_module_line     debug_log.module_line%TYPE;
        exp_action_name     CONSTANT debug_log.action_name%TYPE := 'ERROR_NAME';
        exp_args            debug_log.arguments%TYPE;
        --
        test_string         CONSTANT VARCHAR2(30)   := 'TODAY';
        test_number         CONSTANT VARCHAR2(30)   := 3.1415;
        test_date           CONSTANT DATE           := SYSDATE;
    BEGIN
        exp_args := bug.get_arguments(test_string, test_number, test_date);
        --
        BEGIN
            exp_module_line := $$PLSQL_LINE + 1;
            bug.raise_error (
                in_action   => exp_action_name,
                in_arg1     => test_string,
                in_arg2     => test_number,
                in_arg3     => test_date
            );
            --
            ut.fail('EXCEPTION_EXPECTED');
        EXCEPTION
        WHEN OTHERS THEN
            -- check log for E flag and action_name
            SELECT * INTO first_record
            FROM debug_log
            WHERE flag = bug.flag_error;
            --
            ut.expect(first_record.module_name).to_equal(exp_module_name);
            ut.expect(first_record.module_line).to_equal(exp_module_line);
            ut.expect(first_record.action_name).to_equal(exp_action_name);
            ut.expect(first_record.arguments).to_equal(exp_args);
            --
            ut.expect(first_record.log_id).to_equal(bug.get_log_id());
            ut.expect(first_record.log_id).to_equal(bug.get_error_id());
            --
            RAISE;
        END;
    END;



    PROCEDURE update_timer AS
        parent_id           debug_log.log_id%TYPE;
        next_record         debug_log%ROWTYPE;
    BEGIN
        parent_id := bug.log_module('PARENT');  -- parent needed
        --
        DBMS_SESSION.SLEEP(1);  -- wait 1 sec
        --
        bug.update_timer();

        -- check log
        SELECT * INTO next_record
        FROM debug_log
        WHERE log_id = parent_id;
        --
        ut.expect(SUBSTR(next_record.timer, 1, 9)).to_equal('00:00:01,');
    END;



    PROCEDURE log_progress AS
        first_record        debug_log%ROWTYPE;
        next_record         debug_log%ROWTYPE;
    BEGIN
        -- init
        bug.log_module('PARENT');  -- parent needed
        bug.log_progress (
            in_progress => 0
        );
        --
        SELECT * INTO first_record
        FROM debug_log
        WHERE flag = bug.flag_longops;
        --
        ut.expect(first_record.arguments).to_equal('0%');

        -- check session longops
        --
        -- @TODO:
        --

        -- increase progress
        DBMS_SESSION.SLEEP(1);  -- wait 1 sec
        --
        bug.log_progress (
            in_progress => 0.5  -- 0.5 = 50%
        );

        -- check log
        SELECT * INTO next_record
        FROM debug_log
        WHERE log_id = first_record.log_id;
        --
        ut.expect(next_record.arguments).to_equal('50%');
        ut.expect(SUBSTR(next_record.timer, 1, 9)).to_equal('00:00:01,');

        -- check session longops
        --
        -- @TODO:
        --
    END;

END;
/
