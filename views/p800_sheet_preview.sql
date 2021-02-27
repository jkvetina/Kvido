CREATE OR REPLACE FORCE VIEW p800_sheet_preview AS
WITH s AS (
    SELECT s.*
    FROM uploaded_file_sheets s
    WHERE s.file_name           = apex.get_item('$FILE')
        AND s.sheet_id          = apex.get_item('$SHEET')
)
SELECT *
FROM (
    SELECT 'Inserted'   AS name_, s.result_inserted     AS value_, 'I' AS filter_ FROM s UNION ALL
    SELECT 'Updated'    AS name_, s.result_updated      AS value_, 'U' AS filter_ FROM s UNION ALL
    SELECT 'Deleted'    AS name_, s.result_deleted      AS value_, 'D' AS filter_ FROM s UNION ALL
    SELECT 'Errors'     AS name_, s.result_errors       AS value_, 'E' AS filter_ FROM s UNION ALL
    SELECT 'Unmatched'  AS name_, s.result_unmatched    AS value_, '-' AS filter_ FROM s
)
WHERE value_ > 0;

