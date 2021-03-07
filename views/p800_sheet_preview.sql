CREATE OR REPLACE FORCE VIEW p800_sheet_preview AS
WITH s AS (
    SELECT
        s.*,
        app.get_duration(l.timer) AS timer
    FROM uploaded_file_sheets s
    LEFT JOIN logs l
        ON l.log_id             = s.result_log_id
    WHERE s.file_name           = apex.get_item('$FILE')
        AND s.sheet_id          = apex.get_item('$SHEET')
        AND s.app_id            = sess.get_app_id()
        AND s.uploader_id       = apex.get_item('$TARGET')
)
SELECT
    t.label_,
    --
    CASE WHEN ROWNUM = 1 THEN
        TO_CHAR(s.updated_at, 'YYYY-MM-DD HH24:MI') ||
        CASE WHEN s.commited_at IS NOT NULL THEN ' COMMIT' END ||
        CASE WHEN s.updated_at IS NOT NULL THEN '<br />' END ||
        s.timer
        END AS supplemental_,
    --
    t.counter_,
    t.filter_
FROM (
    SELECT 'Inserted'   AS label_,  s.result_inserted   AS counter_,  'I' AS filter_ FROM s UNION ALL
    SELECT 'Updated'    AS label_,  s.result_updated    AS counter_,  'U' AS filter_ FROM s UNION ALL
    SELECT 'Deleted'    AS label_,  s.result_deleted    AS counter_,  'D' AS filter_ FROM s UNION ALL
    SELECT 'Errors'     AS label_,  s.result_errors     AS counter_,  'E' AS filter_ FROM s UNION ALL
    SELECT 'Unmatched'  AS label_,  s.result_unmatched  AS counter_,  '-' AS filter_ FROM s
) t
CROSS JOIN s
WHERE t.counter_ > 0;

