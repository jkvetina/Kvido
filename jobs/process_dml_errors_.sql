DECLARE
    in_job_name             CONSTANT VARCHAR2(30)   := 'PROCESS_DML_ERRORS_';
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
        job_type            => 'STORED_PROCEDURE',
        job_action          => 'process_dml_errors',    -- procedure, not package
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=MINUTELY;INTERVAL=5;',
        enabled             => FALSE,
        comments            => 'Merge DML ERR records into proper debug_log tree'
    );
    --
    DBMS_SCHEDULER.SET_ATTRIBUTE(in_job_name, 'JOB_PRIORITY', 5);  -- lower priority
    DBMS_SCHEDULER.ENABLE(in_job_name);
    COMMIT;
    --
    IF in_run_immediatelly THEN
        DBMS_SCHEDULER.RUN_JOB(in_job_name);
        COMMIT;
    END IF;
END;
/

