CREATE OR REPLACE VIEW p800_sheet_columns_mapping AS
SELECT  -- passed and matched columns
    c.column_id,
    c.column_name       AS source_column,
    c.data_type,
    c.format_mask,
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
        END AS status
FROM uploaded_file_cols c
LEFT JOIN uploaders_mapping m
    ON m.app_id         = sess.get_app_id()
    AND m.uploader_id   = apex.get_item('$TARGET')
    AND m.source_column = c.column_name
    AND m.is_hidden     IS NULL
LEFT JOIN p860_uploaders_mapping d
    ON d.app_id         = m.app_id
    AND d.uploader_id   = m.uploader_id
    AND d.source_column = m.source_column
WHERE c.file_name       = apex.get_item('$FILE')
    AND c.sheet_id      = apex.get_item('$SHEET')
UNION ALL
SELECT  -- missing columns
    NULL                AS column_id,
    NULL                AS source_column,
    NULL                AS data_type,
    NULL                AS format_mask,
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
        WHEN (m.is_key = 'Y' OR m.is_nn = 'Y')
            THEN apex.get_icon('fa-warning')
        END AS status
FROM uploaders_mapping m
LEFT JOIN p860_uploaders_mapping d
    ON d.app_id         = m.app_id
    AND d.uploader_id   = m.uploader_id
    AND d.source_column = m.source_column
LEFT JOIN uploaded_file_cols c
    ON c.column_name    = m.source_column
    AND c.file_name     = apex.get_item('$FILE')
    AND c.sheet_id      = apex.get_item('$SHEET')
WHERE m.app_id          = sess.get_app_id()
    AND m.uploader_id   = apex.get_item('$TARGET')
    AND m.is_hidden     IS NULL
    AND c.column_name   IS NULL;
