CREATE OR REPLACE TRIGGER navigation_groups__
FOR UPDATE OR INSERT OR DELETE ON navigation_groups
COMPOUND TRIGGER

    in_updated_by       CONSTANT users.updated_by%TYPE  := sess.get_user_id();
    in_updated_at       CONSTANT users.updated_at%TYPE  := SYSDATE;
    --
    rows_inserted       SIMPLE_INTEGER := 0;
    rows_updated        SIMPLE_INTEGER := 0;
    rows_deleted        SIMPLE_INTEGER := 0;
    --
    is_audited          VARCHAR2(1);
    last_rowid          ROWID;                          -- mini audit
    --
    root_log_id         logs.log_id%TYPE;



    BEFORE STATEMENT IS
    BEGIN
        root_log_id := tree.log_module();  -- to track all folowing events under one tree
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END BEFORE STATEMENT;



    BEFORE EACH ROW IS
    BEGIN
        IF NOT DELETING THEN
            -- overwrite some values
            :NEW.app_id         := COALESCE(:NEW.app_id, sess.get_app_id());
            --
            :NEW.updated_by     := in_updated_by;
            :NEW.updated_at     := in_updated_at;
        END IF;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END BEFORE EACH ROW;



    AFTER EACH ROW IS
    BEGIN
        -- track affected rows
        IF INSERTING THEN
            rows_inserted       := rows_inserted + 1;
            last_rowid          := :NEW.ROWID;
        ELSIF UPDATING THEN
            rows_updated        := rows_updated + 1;
            last_rowid          := :OLD.ROWID;
        ELSIF DELETING THEN
            rows_deleted        := rows_deleted + 1;
            last_rowid          := :OLD.ROWID;
        END IF;
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END AFTER EACH ROW;



    AFTER STATEMENT IS
    BEGIN
        -- store affected rows and time needed to process trigger
        tree.update_trigger (
            in_log_id           => root_log_id,
            in_rows_inserted    => rows_inserted,
            in_rows_updated     => rows_updated,
            in_rows_deleted     => rows_deleted,
            in_last_rowid       => TO_CHAR(last_rowid)
        );
    EXCEPTION
    WHEN tree.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        tree.raise_error();
    END AFTER STATEMENT;

END;
/
