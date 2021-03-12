CREATE OR REPLACE FORCE VIEW p800_sheet_columns_mapping AS
WITH p AS (
    -- passed and matched columns
    SELECT
        c.column_id,
        c.column_name       AS source_column,
        --
        c.data_type || NULLIF(' (' || c.format_mask || ')', ' ()') AS data_type,
        --
        d.column_id         AS target_column_id,
        m.target_column     AS target_column,
        d.data_type         AS target_data_type,
        --
        CASE WHEN m.is_key = 'Y' THEN apex.get_icon('fa-check-square') END AS is_key,
        CASE WHEN m.is_nn  = 'Y' THEN apex.get_icon('fa-check-square') END AS is_nn,
        m.overwrite_value,
        --
        CASE
            WHEN m.target_column IS NOT NULL
                THEN apex.get_icon('fa-check-square')
            END AS status,
        --
        CASE WHEN m.target_column IS NOT NULL THEN 'Y' END  AS status_mapped,
        NULL                                                AS status_missing,
        --
        CASE WHEN d.column_id IS NOT NULL THEN 'U' END AS allow_changes  -- U = update
    FROM uploaded_file_cols c
    LEFT JOIN uploaders_mapping m
        ON m.app_id         = sess.get_app_id()
        AND m.uploader_id   = apex.get_item('$TARGET')
        AND m.source_column = c.column_name
        AND m.is_hidden     IS NULL
        ON d.table_name     = m.uploader_id
        AND d.column_name   = m.source_column
    WHERE c.file_name       = apex.get_item('$FILE')
        AND c.sheet_id      = apex.get_item('$SHEET')
    LEFT JOIN p951_table_columns d
),
m AS (
    -- missing columns
    SELECT
        (
            SELECT MAX(p.column_id)
            FROM p
            WHERE p.target_column_id < d.column_id
        ) AS column_id,
        --
        NULL                AS source_column,
        NULL                AS data_type,
        d.column_id         AS target_column_id,
        m.target_column     AS target_column,
        d.data_type         AS target_data_type,
        --
        CASE WHEN m.is_key = 'Y' THEN apex.get_icon('fa-check-square') END AS is_key,
        CASE WHEN m.is_nn  = 'Y' THEN apex.get_icon('fa-check-square') END AS is_nn,
        m.overwrite_value,
        --
        CASE
            WHEN (m.is_key = 'Y' OR m.is_nn = 'Y')
                THEN apex.get_icon('fa-warning')
            END AS status,
        --
        NULL                                                        AS status_mapped,
        CASE WHEN (m.is_key = 'Y' OR m.is_nn = 'Y') THEN 'Y' END    AS status_missing,
        --
        CASE WHEN d.column_id IS NOT NULL THEN 'U' END AS allow_changes  -- U = update
    FROM uploaders_mapping m
    LEFT JOIN p951_table_columns d
        ON d.table_name     = m.uploader_id
        AND d.column_name   = m.target_column
    LEFT JOIN uploaded_file_cols c
        ON c.column_name    = m.source_column
        AND c.file_name     = apex.get_item('$FILE')
        AND c.sheet_id      = apex.get_item('$SHEET')
    WHERE m.app_id          = sess.get_app_id()
        AND m.uploader_id   = apex.get_item('$TARGET')
        AND m.is_hidden     IS NULL
        AND c.column_name   IS NULL
)
SELECT
    p.column_id,
    p.source_column,
    p.data_type,
    p.target_column_id,
    p.target_column,
    p.target_data_type,
    p.is_key,
    p.is_nn,
    p.overwrite_value,
    p.status,
    p.status_mapped,
    p.status_missing,
    p.allow_changes
FROM p
UNION ALL
SELECT
    m.column_id,
    m.source_column,
    m.data_type,
    m.target_column_id,
    m.target_column,
    m.target_data_type,
    m.is_key,
    m.is_nn,
    m.overwrite_value,
    m.status,
    m.status_mapped,
    m.status_missing,
    m.allow_changes
FROM m;

