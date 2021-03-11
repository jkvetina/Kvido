DECLARE
    in_job_name             CONSTANT VARCHAR2(30)   := 'PURGE_DM_TABLES';
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
    FOR c IN (
        SELECT name
        FROM dm_user_models
    ) LOOP
        DBMS_DATA_MINING.DROP_MODEL(c.name);
    END LOOP;
    COMMIT;
END;]',
        number_of_arguments => 0,
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=60',
        end_date            => NULL,
        enabled             => FALSE,
        auto_drop           => FALSE,
        comments            => 'Delete unwanted DM tables'
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

