CREATE OR REPLACE VIEW p860_uploaders_mapping AS
SELECT
    u.app_id,
    u.uploader_id,
    c.column_id,
    c.column_name           AS target_column,
    --
    CASE WHEN p.column_name IS NOT NULL THEN 'Y' END AS is_key,
    CASE WHEN c.nullable = 'N'          THEN 'Y' END AS is_nn,
    m.is_hidden,
    --
    --
    c.data_type ||
    CASE
        WHEN c.data_type LIKE '%CHAR%' OR c.data_type = 'RAW' THEN
            DECODE(NVL(c.char_length, 0), 0, '',
                '(' || c.char_length || DECODE(c.char_used, 'C', ' CHAR', '') || ')'
            )
        WHEN c.data_type = 'NUMBER' THEN
            DECODE(NVL(c.data_precision || c.data_scale, 0), 0, '',
                DECODE(NVL(c.data_scale, 0), 0, '(' || c.data_precision || ')',
                    '(' || c.data_precision || ',' || c.data_scale || ')'
                )
            )
        END AS data_type,
    --
    c.column_name AS source_column,
    --
    m.overwrite_value
FROM uploaders u
JOIN user_tab_cols c
    ON c.table_name         = u.target_table
LEFT JOIN user_constraints n
    ON n.table_name         = c.table_name
    AND n.constraint_type   = 'P'
LEFT JOIN user_cons_columns p
    ON p.constraint_name    = n.constraint_name
    AND p.column_name       = c.column_name
LEFT JOIN uploaders_mapping m
    ON m.app_id             = sess.get_app_id()
    AND m.uploader_id       = u.uploader_id
    AND m.target_column     = c.column_name;

