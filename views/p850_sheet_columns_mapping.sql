CREATE OR REPLACE VIEW p850_sheet_columns_mapping AS
SELECT  -- passed and matched columns
    c.column_id,
    c.column_name       AS source_column,
    c.data_type,
    c.format_mask,
    m.target_column,
    m.data_type         AS target_data_type,
    CASE WHEN m.is_key = 'Y' THEN apex.get_icon('fa-check-square') END AS is_key,
    CASE WHEN m.is_nn  = 'Y' THEN apex.get_icon('fa-check-square') END AS is_nn,
    m.overwrite_value
FROM uploaded_file_cols c
LEFT JOIN p860_uploaders_mapping m
    ON m.app_id         = sess.get_app_id()
    AND m.uploader_id   = apex.get_item('$TARGET')
    AND m.source_column = c.column_name
    AND m.is_hidden     IS NULL
WHERE c.file_name       = apex.get_item('$FILE')
    AND c.sheet_id      = apex.get_item('$SHEET')
UNION ALL
SELECT  -- missing columns
    NULL                AS column_id,
    NULL                AS source_column,
    NULL                AS data_type,
    NULL                AS format_mask,
    m.data_type         AS target_data_type,
    NULL                AS target_data_type,
    CASE WHEN m.is_key = 'Y' THEN apex.get_icon('fa-check-square') END AS is_key,
    CASE WHEN m.is_nn  = 'Y' THEN apex.get_icon('fa-check-square') END AS is_nn,
    m.overwrite_value
FROM p860_uploaders_mapping m
LEFT JOIN uploaded_file_cols c
    ON c.column_name    = m.source_column
    AND c.file_name     = apex.get_item('$FILE')
    AND c.sheet_id      = apex.get_item('$SHEET')
WHERE m.app_id          = sess.get_app_id()
    AND m.uploader_id   = apex.get_item('$TARGET')
    AND m.is_hidden     IS NULL
    AND c.column_name   IS NULL;
