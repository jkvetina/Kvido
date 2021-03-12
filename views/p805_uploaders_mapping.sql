CREATE OR REPLACE FORCE VIEW p805_uploaders_mapping AS
SELECT
    u.app_id,
    u.uploader_id,
    --
    d.column_id,
    d.column_name           AS target_column,
    --
    m.is_key,
    m.is_nn,
    m.is_hidden,
    --
    CASE WHEN p.column_name IS NOT NULL THEN 'Y' END AS is_key_def,
    CASE WHEN d.nn          IS NOT NULL THEN 'Y' END AS is_nn_def,
    --
    CASE WHEN m.target_column IS NULL AND d.column_name IN (
            'UPDATED_BY', 'UPDATED_AT',
            'CREATED_BY', 'CREATED_AT'
        ) THEN 'Y'
        ELSE m.is_hidden
        END AS is_hidden_def,
    --
    d.data_type,
    --
    m.source_column,
    m.overwrite_value
FROM uploaders u
JOIN p951_table_columns d
    ON d.table_name         = u.target_table
LEFT JOIN user_constraints n
    ON n.table_name         = d.table_name
    AND n.constraint_type   = 'P'
LEFT JOIN user_cons_columns p
    ON p.constraint_name    = n.constraint_name
    AND p.column_name       = d.column_name
LEFT JOIN uploaders_mapping m
    ON m.app_id             = sess.get_app_id()
    AND m.uploader_id       = u.uploader_id
    AND m.target_column     = d.column_name;

