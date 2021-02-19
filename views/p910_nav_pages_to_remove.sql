CREATE OR REPLACE VIEW p910_nav_pages_to_remove AS
SELECT n.app_id, n.page_id
FROM navigation n
LEFT JOIN apex_application_pages p
    ON p.application_id     = n.app_id
    AND p.page_id           = n.page_id
WHERE n.app_id              = sess.get_app_id()
    AND n.page_id           BETWEEN 1 AND 999   -- sess.app_min_page AND sess.app_max_page
    AND p.application_id    IS NULL;
