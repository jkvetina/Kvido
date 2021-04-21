BEGIN
    sess.create_session('DEV', 700);

    -- refresh ERR table
    BEGIN
        DBMS_UTILITY.EXEC_DDL_STATEMENT('DROP TABLE ' || 'UPLOADERS_U$');
    EXCEPTION
    WHEN OTHERS THEN
        NULL;
    END;
    --
    DBMS_ERRLOG.CREATE_ERROR_LOG (
        dml_table_name          => 'UPLOADERS',
        err_log_table_name      => 'UPLOADERS_U$',
        err_log_table_owner     => USER,
        err_log_table_space     => NULL,
        skip_unsupported        => TRUE
    );
    --
    -- RECOMPILE
    --
    recompile();
END;
/

ALTER TABLE uploaders_u$ MODIFY ORA_ERR_ROWID$ VARCHAR2(30);
--ALTER TABLE uploaders_u$ MODIFY ORA_ERR_ROWID$ UROWID;

