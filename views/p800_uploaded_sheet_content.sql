CREATE OR REPLACE FORCE VIEW p800_uploaded_sheet_content AS
WITH s AS (
    SELECT
        s.*,
        NVL(apex.get_item('$TARGET'), s.uploader_id) AS target
    FROM uploaded_file_sheets s
    WHERE s.file_name   = apex.get_item('$FILE')
        AND s.sheet_id  = apex.get_item('$SHEET')
),
m AS (
    SELECT
        SUM(CASE WHEN m.status_mapped  = 'Y' THEN 1 ELSE 0 END) AS mapped_cols,
        SUM(CASE WHEN m.status_missing = 'Y' THEN 1 ELSE 0 END) AS missing_cols
    FROM p800_sheet_columns_mapping m
)
SELECT
    'Columns' AS list_label,
    --
    'Mapped: ' || m.mapped_cols ||
        CASE WHEN m.missing_cols > 0 THEN ', Missing: ' || m.missing_cols END
        AS supplemental,
    --
    s.sheet_cols        AS count_,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P800_FILE,P800_SHEET,P800_TARGET,P800_SHOW_COLS,P800_SHOW_ROWS,P800_RESET',
        in_values       => s.file_name || ',' || s.sheet_id || ',' || s.target || ',Y,,'
    ) AS target_url
FROM s
CROSS JOIN m
UNION ALL
--
SELECT
    'Rows'              AS list_label,
    NULL                AS supplemental,
    s.sheet_rows        AS count_,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P800_FILE,P800_SHEET,P800_TARGET,P800_SHOW_COLS,P800_SHOW_ROWS,P800_RESET',
        in_values       => s.file_name || ',' || s.sheet_id || ',' || s.target || ',,Y,'
    ) AS target_url
FROM s;

