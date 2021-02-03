CREATE OR REPLACE VIEW p910_nav_groups AS
SELECT
    g.page_id,
    g.page_group,
    COUNT(p.page_id)            AS pages
FROM navigation_groups g
LEFT JOIN apex_application_pages p
    ON p.application_id         = g.app_id
    AND p.page_group            = g.page_group
WHERE g.app_id                  = sess.get_app_id()
    AND g.page_group            = NVL(apex.get_item('$PAGE_GROUP'), g.page_group)
GROUP BY g.page_id, g.page_group;
