CREATE OR REPLACE VIEW p850_uploaded_targets AS
WITH s AS (
    SELECT s.*
    FROM uploaded_file_sheets s
    WHERE s.file_name   = apex.get_item('$FILE')
        AND s.sheet_id  = apex.get_item('$SHEET')
)
SELECT
    CASE WHEN u.uploader_id = apex.get_item('$TARGET')
        THEN '<b>' || NVL(u.uploader_id, '-') || '</b>'
        ELSE          NVL(u.uploader_id, '-')
        END AS list_label,
    --
    '[' || u.page_id || '] ' || u.page_name || ' - ' || u.region_name AS supplemental,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P850_RESET,P850_TARGET',
        in_values       => ',' || u.uploader_id
    ) AS target_url
FROM p860_uploaders_possible u
CROSS JOIN s
WHERE u.is_active = 'Y'
    AND 1 = CASE
        WHEN u.uploader_id IS NOT NULL AND u.uploader_id != apex.get_item('$TARGET')
            THEN 0
        ELSE 1 END;

