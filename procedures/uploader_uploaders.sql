CREATE OR REPLACE PROCEDURE uploader_uploaders (
    in_file_name        uploaded_file_sheets.file_name%TYPE,
    in_sheet_id         uploaded_file_sheets.sheet_id%TYPE,
    in_uploader_id      uploaded_file_sheets.uploader_id%TYPE
)
AS
    TYPE target_table_t
        IS TABLE OF     uploaders_u$%ROWTYPE INDEX BY PLS_INTEGER;
    --
    target_table        target_table_t;
    --
    rows_to_insert      uploader.target_rows_t      := uploader.target_rows_t();
    rows_to_update      uploader.target_rows_t      := uploader.target_rows_t();
    rows_to_delete      uploader.target_rows_t      := uploader.target_rows_t();
    --
    indexes_insert      uploader.target_ids_t       := uploader.target_ids_t();
    indexes_update      uploader.target_ids_t       := uploader.target_ids_t();
    --
    rows_inserted#      SIMPLE_INTEGER := 0;
    rows_updated#       SIMPLE_INTEGER := 0;
    rows_deleted#       SIMPLE_INTEGER := 0;
    rows_errors#        SIMPLE_INTEGER := 0;
    --
    idx                 PLS_INTEGER;
    delete_flag_col     VARCHAR2(30);
BEGIN
    tree.log_module(in_file_name, in_sheet_id, in_uploader_id);

    -- get delete_flag column name
    BEGIN
        SELECT 'COL' || LPAD(c.column_id, 3, '0') INTO delete_flag_col
        FROM uploaded_file_cols c
        WHERE c.file_name       = in_file_name
            AND c.column_name   = uploader.delete_flag_name;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- bulk collect rows from uploaded file into memory
    SELECT
        p.line_number - 1       AS ORA_ERR_NUMBER$,    -- NUMBER            -- used for row number
        NULL                    AS ORA_ERR_MESG$,      -- VARCHAR2(2000)    -- used for error code
        NULL                    AS ORA_ERR_ROWID$,     -- UROWID
        p.col014                AS ORA_ERR_OPTYP$,     -- VARCHAR2(2)       -- used for delete flag at start, type of operation at the end
        /**   ^ delete_flag_col */
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
            p_xlsx_sheet_name   => s.sheet_xml_id,                          -- @TODO: fix CSV later
            p_skip_rows         => 1
        )) p
    WHERE f.file_name = in_file_name;

    -- split rows into rows for delete or insert
    FOR i IN 1 .. target_table.COUNT LOOP
        IF target_table(i).ORA_ERR_OPTYP$ = uploader.delete_flag_value THEN
            rows_to_delete(i) := i;
        ELSE
            rows_to_insert(i) := i;
        END IF;
    END LOOP;

    -- delete flagged rows
    BEGIN
        FORALL i IN INDICES OF rows_to_delete
        DELETE FROM uploaders u
        WHERE /** GENERATE_WHERE:START(3) */
            u.app_id            = target_table(i).app_id
            AND u.uploader_id   = target_table(i).uploader_id
            ;/** GENERATE_WHERE:END */
    END;

    -- calculate deleted rows
    idx := rows_to_delete.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_deleted# := rows_deleted# + 1;
            target_table(idx).ORA_ERR_OPTYP$ := 'D';
        END IF;
        --
        idx := rows_to_delete.NEXT(idx);
    END LOOP;

    -- prepare index maps for exceptions
    idx := rows_to_insert.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        indexes_insert.EXTEND;
        indexes_insert(indexes_insert.LAST) := idx;
        idx := rows_to_insert.NEXT(idx);
    END LOOP;

    -- insert rows first, then try to update failed rows
    BEGIN
        FORALL i IN INDICES OF rows_to_insert
        SAVE EXCEPTIONS
        INSERT INTO uploaders (
            /** GENERATE_COLUMNS:START(3) */
            app_id,
            uploader_id,
            target_table,
            target_page_id,
            pre_procedure,
            post_procedure,
            is_active,
            updated_by,
            updated_at
            /** GENERATE_COLUMNS:END */
        )
        VALUES (
            /** GENERATE_VALUES:START(3) */
            target_table(i).app_id,
            target_table(i).uploader_id,
            target_table(i).target_table,
            target_table(i).target_page_id,
            target_table(i).pre_procedure,
            target_table(i).post_procedure,
            target_table(i).is_active,
            target_table(i).updated_by,
            target_table(i).updated_at
            /** GENERATE_VALUES:END */
        );
    EXCEPTION
    WHEN uploader.forall_failed THEN
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            idx := indexes_insert(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);

            -- on dup_val_on_index mark row for update
            IF SQL%BULK_EXCEPTIONS(i).ERROR_CODE = 1 THEN
                rows_to_update(idx) := idx;
                CONTINUE;
            END IF;

            -- otherwise mark as error
            rows_errors#                        := rows_errors# + 1;
            target_table(idx).ORA_ERR_MESG$     := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
            target_table(idx).ORA_ERR_OPTYP$    := 'E';
        END LOOP;
    WHEN OTHERS THEN
        RAISE;
    END;

    -- calculate inserted rows
    idx := rows_to_insert.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_inserted#                      := rows_inserted# + 1;
            target_table(idx).ORA_ERR_OPTYP$    := 'I';
        END IF;
        --
        idx := rows_to_insert.NEXT(idx);
    END LOOP;

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
        SET /** GENERATE_UPDATE:START(3) */
            u.target_table      = target_table(i).target_table,
            u.target_page_id    = target_table(i).target_page_id,
            u.pre_procedure     = target_table(i).pre_procedure,
            u.post_procedure    = target_table(i).post_procedure,
            u.is_active         = target_table(i).is_active
            /** GENERATE_UPDATE:END */
        WHERE /** GENERATE_WHERE:START(3) */
            u.app_id            = target_table(i).app_id
            AND u.uploader_id   = target_table(i).uploader_id
            ;/** GENERATE_WHERE:END */
    EXCEPTION
    WHEN uploader.forall_failed THEN
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            idx := indexes_update(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
            --
            rows_errors#                        := rows_errors# + 1;
            target_table(idx).ORA_ERR_MESG$     := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
            target_table(idx).ORA_ERR_OPTYP$    := 'E';
        END LOOP;
    WHEN OTHERS THEN
        RAISE;
    END;

    -- calculate updated rows
    idx := rows_to_update.FIRST;
    WHILE (idx IS NOT NULL) LOOP
        IF SQL%BULK_ROWCOUNT(idx) > 0 THEN
            rows_updated#                       := rows_updated# + 1;
            target_table(idx).ORA_ERR_OPTYP$    := 'U';
        END IF;
        --
        idx := rows_to_update.NEXT(idx);
    END LOOP;

    --
    -- @TODO: try to evaluate catched errors to get meaningful messages
    --
    NULL;

    -- store uploaded data for further investigations
    DELETE FROM uploaders_u$ t
    WHERE t.ORA_ERR_TAG$ = sess.get_session_id();
    --
    FORALL i IN 1 .. target_table.COUNT
    INSERT INTO uploaders_u$ VALUES target_table(i);
    --
    tree.log_result (
        'ROWS: ' || TO_CHAR(target_table.COUNT) ||
        CASE WHEN rows_inserted# > 0 THEN ', INSERTED: ' || rows_inserted# END ||
        CASE WHEN rows_updated#  > 0 THEN ', UPDATED: '  || rows_updated#  END ||
        CASE WHEN rows_deleted#  > 0 THEN ', DELETED: '  || rows_deleted#  END ||
        CASE WHEN rows_errors#   > 0 THEN ', ERRORS: '   || rows_errors#   END
    );
    tree.update_timer();
EXCEPTION
WHEN tree.app_exception THEN
    RAISE;
WHEN OTHERS THEN
    tree.raise_error();
END;
/
