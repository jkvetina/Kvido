CREATE OR REPLACE FORCE VIEW p805_uploaders AS
SELECT
    u.uploader_id,
    u.target_table,
    u.target_page_id,
    u.pre_procedure,
    u.post_procedure,
    u.is_active,
    --
    p.page_name,
    p.region_name,
    p.page_group,
    p.auth_scheme,
    --
    apex.get_page_link(u.target_page_id) AS page_link,
    --
    p.action,
    p.action_link,
    --
    apex.get_developer_page_link(u.target_page_id, p.region_id) AS apex_,
    --
    p.mappings_check,
    p.region_check,
    --
    'UD' AS allow_changes  -- U = update, D = delete
FROM uploaders u
LEFT JOIN p805_uploaders_possible p
    ON p.uploader_id    = u.uploader_id
WHERE u.app_id          = sess.get_app_id()
UNION ALL
SELECT
    p.table_name        AS uploader_id,
    p.table_name        AS target_table,
    p.page_id           AS target_page_id,
    NULL                AS pre_procedure,
    NULL                AS post_procedure,
    NULL                AS is_active,
    --
    p.page_name,
    p.region_name,
    p.page_group,
    p.auth_scheme,
    --
    apex.get_page_link(p.page_id)                                   AS page_link,
    --
    apex.get_icon('fa-plus-square', 'Add record to Uploaders')      AS action,
    p.action_link,
    --
    apex.get_developer_page_link(p.page_id, p.region_id)            AS apex_,
    --
    p.mappings_check,
    p.region_check,
    --
    NULL AS allow_changes  -- NULL = nothing
FROM p805_uploaders_possible p
WHERE p.uploader_id IS NULL;

