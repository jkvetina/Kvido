CREATE OR REPLACE PROCEDURE uploader_uploaders (
    in_file_name        uploaded_file_sheets.file_name%TYPE,
    in_sheet_id         uploaded_file_sheets.sheet_id%TYPE,
    in_uploader_id      uploaded_file_sheets.uploader_id%TYPE
)
AS
    target_table        uploader.target_table_t;
    delete_flag_col     VARCHAR2(30);
    --
    rows_to_insert      uploader.target_rows_t      := uploader.target_rows_t();
    rows_to_update      uploader.target_rows_t      := uploader.target_rows_t();
    rows_to_delete      uploader.target_rows_t      := uploader.target_rows_t();
    --
    indexes_insert      uploader.target_ids_t       := uploader.target_ids_t();
    indexes_update      uploader.target_ids_t       := uploader.target_ids_t();
    
    rows_inserted#      SIMPLE_INTEGER := 0;
    rows_updated#       SIMPLE_INTEGER := 0;
    rows_deleted#       SIMPLE_INTEGER := 0;
    --
    idx                 PLS_INTEGER;
BEGIN
    tree.log_module(in_file_name, in_sheet_id, in_uploader_id);

    -- cleanup table for current session
    DELETE FROM uploaders_u$ t
    WHERE t.ORA_ERR_TAG$        = sess.get_session_id();
    --
    -- @TODO: store results at the end
    --



    -- get delete_flag column name
    --
    --
    --
    delete_flag_col := 'COL014';



    -- bulk collect rows from uploaded file into memory
    SELECT
        NULL                    AS ORA_ERR_NUMBER$,    -- NUMBER            -- used for error code
        NULL                    AS ORA_ERR_MESG$,      -- VARCHAR2(2000)
        NULL                    AS ORA_ERR_ROWID$,     -- UROWID
        p.col014                AS ORA_ERR_OPTYP$,     -- VARCHAR2(2)       -- used for delete flag
        sess.get_session_id()   AS ORA_ERR_TAG$,       -- VARCHAR2(2000)    -- used for session_id
        --
        /** GENERATE_MAPPINGS:START(2) */
        sess.get_app_id()                       AS app_id,
        --
        --NULL                                    AS uploader_id,
        --
        NULLIF(p.col002, '[Data Error: N/A]')   AS uploader_id,             -- missing in mappings
        NULLIF(p.col002, '[Data Error: N/A]')   AS target_table,
        NULLIF(p.col007, '[Data Error: N/A]')   AS target_page_id,
        NULLIF(p.col009, '[Data Error: N/A]')   AS pre_procedure,
        NULLIF(p.col010, '[Data Error: N/A]')   AS post_procedure,
        --
        REPLACE(NULLIF(p.col011, '[Data Error: N/A]'), 'Checked', 'Y') AS is_active,
        --NULLIF(p.col011, '[Data Error: N/A]')   AS is_active,
        --
        sess.get_user_id()      AS updated_by,
        SYSDATE                 AS updated_at
        /** GENERATE_MAPPINGS:END */
    BULK COLLECT INTO target_table
    FROM uploaded_files f
    JOIN uploaded_file_sheets s
        ON s.file_name          = f.file_name
        AND s.sheet_id          = in_sheet_id
    CROSS JOIN TABLE(APEX_DATA_PARSER.PARSE(
            p_content           => f.blob_content,
            p_file_name         => f.file_name,
            p_xlsx_sheet_name   => s.sheet_xml_id,  -- fix CSV later
            p_skip_rows         => 1
        )) p
    WHERE f.file_name = in_file_name;

    -- split rows into rows for delete or insert/update
    FOR i IN 1 .. target_table.COUNT LOOP
        IF target_table(i).ORA_ERR_OPTYP$ = 'Y' THEN
            rows_to_delete(i) := i;
            DBMS_OUTPUT.PUT_LINE('MARK: (' || i || ') DEL*');
        ELSE
            --rows_to_insert.EXTEND;
            --rows_to_insert(rows_to_insert.LAST) := i;
            rows_to_insert(i) := i;
            DBMS_OUTPUT.PUT_LINE('MARK: (' || i || ') INS');
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--');

    -- delete flagged rows
    BEGIN
        FORALL i IN INDICES OF rows_to_delete
        DELETE FROM uploaders u
        WHERE /** MAPPING.IS_KEY */
            u.app_id            = target_table(i).app_id
            AND u.uploader_id   = target_table(i).uploader_id;
        --
        -- @TODO: catch exceptions ??
        --
    END;

    -- calculate deleted rows
    idx := rows_to_delete.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_deleted# := rows_deleted# + 1;
            target_table(idx).ORA_ERR_MESG$ := 'D';
            DBMS_OUTPUT.PUT_LINE('DELETED: ' || idx || ' ' || target_table(idx).uploader_id);
        END IF;
        --
        idx := rows_to_delete.NEXT(idx);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--');



    -- prepare index maps for exceptions
    idx := rows_to_insert.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        indexes_insert.EXTEND;
        indexes_insert(indexes_insert.LAST) := idx;
        idx := rows_to_insert.NEXT(idx);
    END LOOP;

    -- insert rows first
    BEGIN
        FORALL i IN INDICES OF rows_to_insert
        SAVE EXCEPTIONS
        INSERT INTO uploaders (
            /** GENERATE_INSERT:START(3) */
            app_id,
            uploader_id,
            target_table,
            target_page_id,
            pre_procedure,
            post_procedure,
            is_active,
            updated_by,
            updated_at
            /** GENERATE_INSERT:END */
        )
        VALUES (
            /** GENERATE_INSERT_VALUES:START(3) */
            target_table(i).app_id,
            target_table(i).uploader_id,
            target_table(i).target_table,
            target_table(i).target_page_id,
            target_table(i).pre_procedure,
            target_table(i).post_procedure,
            target_table(i).is_active,
            target_table(i).updated_by,
            target_table(i).updated_at
            /** GENERATE_INSERT_VALUES:END */
        );
    EXCEPTION
    WHEN uploader.forall_failed THEN
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            idx := indexes_insert(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);

            -- on dup_val_on_index mark row for update
            IF SQL%BULK_EXCEPTIONS(i).ERROR_CODE = 1 THEN
                rows_to_update(idx) := idx;
                DBMS_OUTPUT.PUT_LINE(i || ' MARK: (' || idx || ') UPD ' || target_table(idx).uploader_id);
                CONTINUE;
            END IF;

            -- otherwise mark as error
            target_table(idx).ORA_ERR_NUMBER$   := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
            target_table(idx).ORA_ERR_MESG$     := 'E';
            DBMS_OUTPUT.PUT_LINE(i || ' ERROR: ' || target_table(idx).ORA_ERR_NUMBER$ || ' (' || idx || ')');
        END LOOP;
    WHEN OTHERS THEN
        RAISE;
    END;
    DBMS_OUTPUT.PUT_LINE('--');

    -- calculate inserted rows
    idx := rows_to_insert.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_inserted# := rows_inserted# + 1;
            target_table(idx).ORA_ERR_MESG$ := 'I';
            DBMS_OUTPUT.PUT_LINE('INSERTED: ' || idx || ' ' || target_table(idx).uploader_id);
        END IF;
        --
        idx := rows_to_insert.NEXT(idx);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--');



    -- prepare index maps for exceptions
    idx := rows_to_update.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        indexes_update.EXTEND;
        indexes_update(indexes_update.LAST) := idx;
        idx := rows_to_update.NEXT(idx);
    END LOOP;

    -- process rows marked for update
    BEGIN
        FORALL i IN INDICES OF rows_to_update
        UPDATE uploaders u
        SET /** SKIP IS_KEY COLUMNS + NOT PASSED COLUMNS */
            u.target_table      = target_table(i).target_table,
            u.target_page_id    = target_table(i).target_page_id,
            u.pre_procedure     = target_table(i).pre_procedure,
            u.post_procedure    = target_table(i).post_procedure,
            u.is_active         = target_table(i).is_active
            -- just keep existing columns commented for easy checks
            --target_table(i).updated_by,  --------------------- not passed
            --target_table(i).updated_at
        WHERE /** MAPPING.IS_KEY */
            u.app_id            = target_table(i).app_id
            AND u.uploader_id   = target_table(i).uploader_id;
    EXCEPTION
    WHEN uploader.forall_failed THEN
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            idx := indexes_update(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
            --
            target_table(idx).ORA_ERR_NUMBER$   := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
            target_table(idx).ORA_ERR_MESG$     := 'E';
            DBMS_OUTPUT.PUT_LINE(i || ' ERROR: ' || target_table(idx).ORA_ERR_NUMBER$ || ' (' || idx || ')');
        END LOOP;
    WHEN OTHERS THEN
        RAISE;
    END;

    -- calculate updated rows
    idx := rows_to_update.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_updated# := rows_updated# + 1;
            target_table(idx).ORA_ERR_MESG$ := 'U';
            DBMS_OUTPUT.PUT_LINE('UPDATED: ' || idx || ' ' || target_table(idx).uploader_id);
        END IF;
        --
        idx := rows_to_update.NEXT(idx);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--');

    -- try to evaluate catched errors to get meaningful messages
    NULL;
    --
    -- @TODO:
    --

    -- results
    DBMS_OUTPUT.PUT_LINE('ROWS     : ' || TO_CHAR(target_table.COUNT));
    DBMS_OUTPUT.PUT_LINE('INSERTED : ' || rows_inserted#);
    DBMS_OUTPUT.PUT_LINE('UPDATED  : ' || rows_updated#);
    DBMS_OUTPUT.PUT_LINE('DELETED  : ' || rows_deleted#);
    DBMS_OUTPUT.PUT_LINE('--');
    -----DBMS_OUTPUT.PUT_LINE('ERRORS   : ' || TO_CHAR(rows_errors.COUNT));
    --
    FOR i IN 1 .. target_table.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            i || ' | ' ||
            target_table(i).ORA_ERR_MESG$ || ' | ' ||
            target_table(i).ORA_ERR_NUMBER$ || ' | ' ||
            target_table(i).uploader_id
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--');
    --
    tree.update_timer();
END;
/
