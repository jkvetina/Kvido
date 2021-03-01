CREATE OR REPLACE FORCE VIEW p800_uploaded_file_sheets AS
SELECT
    s.sheet_name        AS list_label,
    s.uploader_id       AS supplemental,
    --
    apex.get_page_link (
        in_page_id      => 800,
        in_names        => 'P800_FILE,P800_SHEET,P800_TARGET',
        in_values       => s.file_name || ',' || s.sheet_id || ',' || s.uploader_id
    )                   AS target_url,
    --
    '<span class="fa ' || CASE
        WHEN s.file_name LIKE '%.xlsx'  THEN 'fa-file-excel-o'
        WHEN s.file_name LIKE '%.csv'   THEN 'fa-file-text-o'
        ELSE 'fa-file-o' END ||
        '"></span>' AS open_,
    --
    uploader.get_basename(s.file_name) AS file_basename,
    --
    s.file_name,
    s.sheet_id,
    s.sheet_xml_id,
    s.sheet_name,
    s.sheet_cols,
    s.sheet_rows,
    s.uploader_id
FROM uploaded_file_sheets s
WHERE (
    s.file_name = apex.get_item('$FILE')
    OR (
        sess.get_page_id()  = 802
        AND s.uploader_id   = NVL(apex.get_item('$UPLOADER'), s.uploader_id)
    )
);

