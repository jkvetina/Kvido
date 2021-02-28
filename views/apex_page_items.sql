CREATE OR REPLACE FORCE VIEW apex_page_items AS
SELECT
    i.item_name,
    apex.get_item(i.item_name) AS item_value,
    --
    CASE
        WHEN (REGEXP_LIKE(sess.get_request(), '[:,]' || i.item_name || '[,:]')
            OR REGEXP_LIKE(sess.get_request(), '[\?&' || ']' || LOWER(i.item_name) || '[=&' || ']')
        )
            THEN NULL
        WHEN apex.get_item(i.item_name) IS NULL
            THEN NULL
        ELSE 'COMPUTED'
        END AS supplemental_
FROM apex_application_page_items i
WHERE i.application_id  = sess.get_app_id()
    AND i.page_id       = sess.get_page_id()
ORDER BY 1;
