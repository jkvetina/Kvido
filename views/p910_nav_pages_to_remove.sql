CREATE OR REPLACE VIEW p910_nav_pages_to_remove AS
SELECT n.app_id, n.page_id
FROM navigation n
LEFT JOIN apex_application_pages a
    ON a.application_id     = n.app_id
    AND a.page_id           = n.page_id
WHERE n.app_id              = sess.get_app_id()
    AND n.page_id           BETWEEN 1 AND 999  -- sess.app_min_page AND sess.app_max_page
    AND a.application_id    IS NULL;
