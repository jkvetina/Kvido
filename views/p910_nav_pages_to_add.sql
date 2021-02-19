CREATE OR REPLACE VIEW p910_nav_pages_to_add AS
SELECT
    p.application_id        AS app_id,
    p.page_id,
    g.parent_id,
    p.page_alias,
    p.page_name,
    p.page_title,
    p.page_id               AS order#,          -- find nearest page in same group (below/above)
    p.page_css_classes      AS css_class,
    --
    'Y'                     AS is_hidden,       -- dont show on default
    --
    p.page_group,
    p.page_id               AS page_link,
    p.authorization_scheme  AS auth_scheme
FROM apex_application_pages p
LEFT JOIN navigation n
    ON n.app_id             = p.application_id
    AND n.page_id           = p.page_id
LEFT JOIN (
    -- find common parent in same group
    SELECT
        p.page_group,
        NVL(MIN(n.parent_id), MAX(n.page_id)) AS parent_id
    FROM navigation n
    JOIN apex_application_pages p
        ON p.application_id = n.app_id
        AND p.page_id       = n.page_id
    GROUP BY p.page_group
) g
    ON g.page_group         = p.page_group
WHERE p.application_id      = sess.get_app_id()
    AND p.page_id           BETWEEN 1 and 999   -- sess.app_min_page AND sess.app_max_page
    AND n.page_id           IS NULL;

