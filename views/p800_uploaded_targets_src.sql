CREATE OR REPLACE FORCE VIEW p800_uploaded_targets_src AS
WITH mapped_cols AS (
    SELECT
        m.uploader_id,
        c.column_name
    FROM uploaded_file_cols c
    JOIN uploaders_mapping m
        ON m.app_id         = sess.get_app_id()
        AND m.source_column = c.column_name
        AND m.is_hidden     IS NULL
    WHERE c.file_name       = apex.get_item('$FILE')
        AND c.sheet_id      = apex.get_item('$SHEET')
),
required_cols AS (
    SELECT
        m.uploader_id,
        m.target_column
    FROM uploaders_mapping m
    WHERE m.app_id          = sess.get_app_id()
        AND m.is_hidden     IS NULL
        AND (
            m.is_key        IS NOT NULL
            OR m.is_nn      IS NOT NULL
        )
)
SELECT
    t.uploader_id,
    NULLIF(COUNT(t.mapped), 0)      AS mapped,
    NULLIF(COUNT(t.missing), 0)     AS missing,
    --
    NULLIF(ROUND(COUNT(t.mapped) / (COUNT(t.mapped) + COUNT(t.missing)) * 100, 0) || '%', '0%') AS perc
FROM (
    SELECT
        m.uploader_id,
        m.column_name       AS mapped,
        NULL                AS missing
    FROM mapped_cols m
    UNION ALL
    SELECT
        r.uploader_id,
        NULL                AS mapped,
        r.target_column     AS missing_cols
    FROM required_cols r
    LEFT JOIN mapped_cols m
        ON m.uploader_id    = r.uploader_id
        AND m.column_name   = r.target_column
    WHERE m.uploader_id     IS NULL
) t
GROUP BY t.uploader_id;

