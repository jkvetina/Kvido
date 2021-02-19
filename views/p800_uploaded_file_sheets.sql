CREATE OR REPLACE VIEW p800_uploaded_file_sheets AS
SELECT
    CASE WHEN s.sheet_id = apex.get_item('$SHEET')
        THEN '<b>' || s.sheet_name || '</b>'
        ELSE          s.sheet_name
        END AS list_label,
    --
    NULL AS supplemental,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P800_FILE,P800_SHEET',
        in_values       => s.file_name || ',' || s.sheet_id
    ) AS target_url,
    --
    s.sheet_id,
    s.sheet_xml_id,
    s.sheet_name,
    s.sheet_cols,
    s.sheet_rows,
    s.uploader_id
    --'ROWS: ' || s.sheet_rows || ', COLS: ' || s.sheet_cols || ', ' || s.uploader_id AS supplemental
FROM uploaded_file_sheets s
WHERE s.file_name = apex.get_item('$FILE');

