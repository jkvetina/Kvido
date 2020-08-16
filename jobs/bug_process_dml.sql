DECLARE
    in_job_name CONSTANT VARCHAR2(30) := 'BUG_PROCESS_DML';
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
        job_action          => 'bug_process_dml_errors',    -- procedure, not package
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=MINUTELY;INTERVAL=5;',
        enabled             => FALSE,
        comments            => 'Merge DML ERR records into proper debug_log tree'
    );
    --
    DBMS_SCHEDULER.SET_ATTRIBUTE(in_job_name, 'JOB_PRIORITY', 5);  -- lower priority
    DBMS_SCHEDULER.ENABLE(in_job_name);
    COMMIT;
END;
/

BEGIN
    DBMS_SCHEDULER.RUN_JOB('BUG_PROCESS_DML');
    COMMIT;
END;
/

/*
SELECT job_name, run_count, failure_count FROM user_scheduler_jobs j ORDER BY 1;
*/
