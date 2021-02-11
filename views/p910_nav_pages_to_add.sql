CREATE OR REPLACE VIEW p910_nav_pages_to_add AS
SELECT
    a.application_id        AS app_id,
    a.page_id,
    p.parent_id,
    a.page_alias,
    a.page_name,
    a.page_title,
    a.page_id               AS order#,          -- find nearest page in same group (below/above)
    s.css_class,
    'Y'                     AS is_hidden,       -- dont show on default
    --
    a.page_group,
    a.page_id               AS page_link,
    a.authorization_scheme  AS auth_scheme
FROM apex_application_pages a
LEFT JOIN navigation n
    ON n.app_id             = a.application_id
    AND n.page_id           = a.page_id
LEFT JOIN (
    -- find common parent in same group
    SELECT
        a.page_group,
        NVL(MIN(n.parent_id), MAX(n.page_id)) AS parent_id
    FROM navigation n
    JOIN apex_application_pages a
        ON a.application_id = n.app_id
        AND a.page_id       = n.page_id
    GROUP BY a.page_group
) p
    ON p.page_group         = a.page_group
LEFT JOIN navigation s
    ON s.app_id             = a.application_id
    AND s.page_id           = p.parent_id
WHERE a.application_id      = sess.get_app_id()
    AND a.page_id           BETWEEN 1 and 999   -- sess.app_min_page AND sess.app_max_page
    AND n.page_id           IS NULL;

