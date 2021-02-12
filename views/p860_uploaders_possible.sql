CREATE OR REPLACE VIEW p860_uploaders_possible AS
SELECT
    t.table_name,
    r.page_id,
    p.page_title            AS page_name,
    r.region_name,
    NVL(r.authorization_scheme, p.authorization_scheme) AS auth_scheme,
    u.uploader_id
FROM user_tables t
JOIN apex_application_page_regions r
    ON r.application_id     = sess.get_app_id()
    AND r.static_id         = t.table_name
JOIN apex_application_pages p
    ON p.application_id     = r.application_id
    AND p.page_id           = r.page_id
LEFT JOIN uploaders u
    ON u.app_id             = r.application_id
    AND u.uploader_id       = r.static_id;

