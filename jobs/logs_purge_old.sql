BEGIN
    DBMS_SCHEDULER.CREATE_JOB('LOGS_PURGE_OLD',
        job_type            => 'STORED_PROCEDURE',
        job_action          => 'ERR.PURGE_OLD',
        number_of_arguments => 0,
        start_date          => SYSDATE,
        end_date            => NULL,
        repeat_interval     => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',
        enabled             => TRUE,
        auto_drop           => FALSE,
        comments            => 'Purge LOGS table'
    );
    COMMIT;
END;
/

BEGIN
    DBMS_SCHEDULER.RUN_JOB('LOGS_PURGE_OLD');
    COMMIT;
END;
/

