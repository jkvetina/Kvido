CREATE OR REPLACE VIEW p910_nav_groups AS
SELECT
    g.app_id,
    g.page_id,
    g.page_group,
    --
    CASE WHEN MAX(s.procedure_name) IS NOT NULL
        THEN '<span class="fa fa-check-square" style="" title="Auth procedure exists"></span>'
        END AS status,
    --
    NULLIF(COUNT(p.page_id), 0)         AS pages,
    MAX(a.authorization_scheme_name)    AS auth_scheme
FROM navigation_groups g
LEFT JOIN apex_application_pages p
    ON p.application_id                 = g.app_id
    AND p.page_group                    = g.page_group
LEFT JOIN apex_application_authorization a
    ON a.application_id                 = p.application_id
    AND a.authorization_scheme_name     = p.authorization_scheme
LEFT JOIN user_procedures s
    ON s.object_name                    = 'AUTH'  -- nav.auth_package
    AND s.procedure_name                = p.authorization_scheme
WHERE g.app_id                          = sess.get_app_id()
GROUP BY g.app_id, g.page_id, g.page_group;
