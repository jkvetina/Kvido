CREATE OR REPLACE VIEW p900_setup AS
SELECT
    s.setup_id,
    --
    s.app_id,
    s.user_id,
    s.page_id,
    --
    CASE WHEN s.page_id IS NOT NULL AND p.page_id IS NULL
        THEN apex.get_icon('fa-warning', 'Page does not exists')
        END AS page_check,
    --
    s.flag,
    s.module_name,
    s.apex_debug,
    s.is_tracked,
    s.updated_by,
    s.updated_at
FROM logs_setup s
LEFT JOIN apex_application_pages p
    ON p.application_id     = s.app_id
    AND p.page_id           = s.page_id
WHERE s.app_id              = sess.get_app_id();

