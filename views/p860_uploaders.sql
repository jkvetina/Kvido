CREATE OR REPLACE VIEW p860_uploaders AS
SELECT
    u.uploader_id,
    u.target_table,
    u.target_page_id,
    u.pre_procedure,
    u.post_procedure,
    u.post_redirect,
    u.is_active,
    --
    p.page_name,
    p.region_name,
    p.auth_scheme,
    --
    apex.get_page_link(u.target_page_id) AS page_link,
    --
    CASE
        WHEN p.auth_scheme IS NOT NULL
            THEN apex.get_icon('fa-check-square', 'Uploader valid')
        END AS status,
    --
    apex.get_developer_page_link(u.target_page_id, p.region_id) AS apex_,
    --
    p.err_table,
    p.err_table_link,
    --
    p.region_check,
    p.region_check_link
FROM uploaders u
LEFT JOIN p860_uploaders_possible p
    ON p.uploader_id    = u.uploader_id
WHERE u.app_id          = sess.get_app_id()
UNION ALL
SELECT
    NULL            AS uploader_id,
    p.table_name    AS target_table,
    p.page_id       AS target_page_id,
    NULL            AS pre_procedure,
    NULL            AS post_procedure,
    NULL            AS post_redirect,
    NULL            AS is_active,
    --
    p.page_name,
    p.region_name,
    p.auth_scheme,
    --
    apex.get_page_link(p.page_id)                                   AS page_link,
    apex.get_icon('fa-plus-square', 'Add record to Uploaders')      AS status,
    apex.get_developer_page_link(p.page_id, p.region_id)            AS apex_,
    --
    p.err_table,
    p.err_table_link,
    --
    p.region_check,
    p.region_check_link
FROM p860_uploaders_possible p
WHERE p.uploader_id IS NULL;

