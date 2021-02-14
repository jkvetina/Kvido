CREATE OR REPLACE VIEW p850_uploaded_sheet_content AS
WITH s AS (
    SELECT s.*
    FROM uploaded_file_sheets s
    WHERE s.file_name   = apex.get_item('$FILE')
        AND s.sheet_id  = apex.get_item('$SHEET')
)
SELECT
    'Columns'           AS list_label,
    NULL                AS supplemental,
    s.sheet_cols        AS count_,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P850_RESET,P850_SHOW_COLS,P850_TARGET',
        in_values       => ',Y,' || NVL(apex.get_item('$TARGET'), s.uploader_id)
    ) AS target_url
FROM s
UNION ALL
SELECT
    'Rows'              AS list_label,
    NULL                AS supplemental,
    s.sheet_rows        AS count_,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P850_RESET,P850_SHOW_COLS,P850_TARGET',
        in_values       => ',Y,' || NVL(apex.get_item('$TARGET'), s.uploader_id)
    ) AS target_url
FROM s;

