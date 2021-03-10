DECLARE
    in_job_name             CONSTANT VARCHAR2(30)   := 'REFRESH_ALL_MVW';
    in_run_immediatelly     CONSTANT BOOLEAN        := FALSE;
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(in_job_name, TRUE);
    EXCEPTION
    WHEN OTHERS THEN
        NULL;
    END;
    --
    DBMS_SCHEDULER.CREATE_JOB (
        job_name            => in_job_name,
        job_type            => 'PLSQL_BLOCK',-- STORED_PROCEDURE
        job_action          => q'[BEGIN
    sess.create_session(USER, 700);
    FOR c IN (
        SELECT m.mview_name
        FROM user_mviews m
    ) LOOP
        tree.log_module('MVW_REFRESH', c.mview_name);
        --
        BEGIN
            DBMS_MVIEW.REFRESH(c.mview_name);
            --
            tree.update_timer();
        EXCEPTION
        WHEN OTHERS THEN
            tree.log_error();
        END;
    END LOOP;
END;]',
        number_of_arguments => 0,
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=DAILY;BYHOUR=0;BYMINUTE=5',
        end_date            => NULL,
        enabled             => FALSE,
        auto_drop           => FALSE,
        comments            => 'Refresh all materialized views'
    );
    --
    DBMS_SCHEDULER.ENABLE(in_job_name);
    COMMIT;
    --
    IF in_run_immediatelly THEN
        DBMS_SCHEDULER.RUN_JOB(in_job_name);
        COMMIT;
    END IF;
END;
/

