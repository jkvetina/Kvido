CREATE OR REPLACE FORCE VIEW p800_uploaded_targets AS
WITH s AS (
    SELECT s.*
    FROM uploaded_file_sheets s
    WHERE s.file_name       = apex.get_item('$FILE')
        AND s.sheet_id      = apex.get_item('$SHEET')
)
SELECT
    NVL(u.uploader_id, '-')/* ||
        CASE WHEN (
                u.uploader_id       = apex.get_item('$TARGET')
                OR s.uploader_id    = apex.get_item('$TARGET')
            )
            THEN ' ' || apex.get_icon('fa-star')
            END*/ AS list_label,
    --
    '[' || u.page_id || '] ' || u.page_name || ' - ' || u.region_name AS supplemental,
    --
    m.perc AS count_,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P800_RESET,P800_FILE,P800_SHEET,P800_TARGET',
        in_values       => 'Y,' || apex.get_item('$FILE') || ',' || apex.get_item('$SHEET') || ',' || u.uploader_id
    ) AS target_url
FROM p805_uploaders_possible u
CROSS JOIN s
JOIN p800_uploaded_targets_src m
    ON m.uploader_id    = u.uploader_id
WHERE u.is_active       = 'Y'
    AND 1 = CASE
        WHEN apex.get_item('$SHOW_TARGETS') IS NOT NULL
            THEN 1
        WHEN u.uploader_id IS NOT NULL AND u.uploader_id != apex.get_item('$TARGET')
            THEN 0
        ELSE 1 END
ORDER BY 1;

