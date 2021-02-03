CREATE OR REPLACE VIEW p910_nav_pages_to_add AS
SELECT
    a.application_id        AS app_id,
    a.page_id,
    NULL                    AS parent_id,       -- find common parent in same group
    NULL AS page_alias,
    NULL                    AS order#,          -- find nearest page in same group (below/above)
    NULL AS label,
    NULL                    AS icon_name,       -- extract from page title
    NULL                    AS css_class,       -- update MANUALLY, dont override
    'Y'                     AS is_hidden,       -- dont show on default
    --
    a.page_group,
    a.page_id               AS page_link,
    a.authorization_scheme  AS auth_scheme
FROM apex_application_pages a
LEFT JOIN navigation n
    ON n.app_id             = a.application_id
    AND n.page_id           = a.page_id
WHERE a.application_id      = 723--sess.get_app_id()
    AND a.page_id           BETWEEN 1 and 999--sess.app_min_page AND sess.app_max_page
    AND n.page_id           IS NULL;
