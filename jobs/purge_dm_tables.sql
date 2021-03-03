BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        'PURGE_DM_TABLES',
        job_type            => 'PLSQL_BLOCK',-- STORED_PROCEDURE
        job_action          => 'BEGIN
    FOR c IN (
        SELECT name
        FROM dm_user_models
    ) LOOP
        DBMS_DATA_MINING.DROP_MODEL(c.name);
    END LOOP;
    COMMIT;
END;',
        number_of_arguments => 0,
        start_date          => SYSDATE,
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=60',
        end_date            => NULL,
        enabled             => FALSE,
        auto_drop           => FALSE,
        comments            => ''
    );
    --
    DBMS_SCHEDULER.ENABLE('PURGE_DM_TABLES');
    COMMIT;
END;
/
