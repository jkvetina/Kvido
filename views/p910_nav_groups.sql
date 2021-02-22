CREATE OR REPLACE FORCE VIEW p910_nav_groups AS
SELECT
    g.app_id,
    g.page_id,
    g.page_group,
    --
    CASE WHEN s.procedure_name IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Auth procedure exists')
        END AS status,
    --
    NULLIF(p.pages, 0)              AS pages,
    a.authorization_scheme_name     AS auth_scheme
    --
    --g.ROWID AS rid
FROM navigation_groups g
JOIN apex_application_pages c
    ON c.application_id                 = g.app_id
    AND c.page_id                       = g.page_id
LEFT JOIN (
    SELECT
        p.page_group,
        COUNT(*) AS pages
    FROM apex_application_pages p
    WHERE p.application_id              = sess.get_app_id()
        AND p.page_group                IS NOT NULL
    GROUP BY p.page_group
) p
    ON p.page_group                     = g.page_group
LEFT JOIN apex_application_authorization a
    ON a.application_id                 = c.application_id
    AND a.authorization_scheme_name     = c.authorization_scheme
LEFT JOIN user_procedures s
    ON s.object_name                    = 'AUTH'  -- nav.auth_package
    AND s.procedure_name                = c.authorization_scheme
WHERE g.app_id                          = sess.get_app_id();

