CREATE OR REPLACE PACKAGE bug_ut AS

    -- %suite
    -- %rollback(manual)
    -- %beforeeach(before_each)
    -- %aftereach(after_each)
    -- %beforeall(before_all)
    -- %afterall(after_all)

    PROCEDURE before_all;
    PROCEDURE after_all;
    PROCEDURE before_each;
    PROCEDURE after_each;



    -- %test
    -- %throws(-20000)
    PROCEDURE raise_error;

    -- %test
    PROCEDURE update_timer;

    -- %test
    PROCEDURE log_progress;

END;
/
