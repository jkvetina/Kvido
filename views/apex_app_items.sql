CREATE OR REPLACE VIEW apex_app_items AS
SELECT
    i.item_name,
    apex.get_item(i.item_name) AS item_value
FROM apex_application_items i
WHERE i.application_id  = sess.get_app_id()
ORDER BY 1;
