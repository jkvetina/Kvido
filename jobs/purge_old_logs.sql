DECLARE
    in_job_name CONSTANT VARCHAR2(30) := 'PURGE_OLD_LOGS';
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(in_job_name, TRUE);  -- force
    EXCEPTION
    WHEN OTHERS THEN
        NULL;
    END;
    --
    DBMS_SCHEDULER.CREATE_JOB (
        job_name            => in_job_name,
        job_type            => 'STORED_PROCEDURE',
        job_action          => 'tree.purge_old',
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',  -- 02:00
        enabled             => FALSE,
        comments            => 'Purge old records from logs table and related tables'
    );
    --
    DBMS_SCHEDULER.SET_ATTRIBUTE(in_job_name, 'JOB_PRIORITY', 5);  -- lower priority
    DBMS_SCHEDULER.ENABLE(in_job_name);
    COMMIT;
END;
/

BEGIN
    DBMS_SCHEDULER.RUN_JOB('PURGE_OLD_LOGS');
    COMMIT;
END;
/
/*
SELECT job_name, run_count, failure_count FROM user_scheduler_jobs j ORDER BY 1;
*/

