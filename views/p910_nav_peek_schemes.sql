CREATE OR REPLACE FORCE VIEW p910_nav_peek_schemes AS
SELECT
    g.auth_scheme,
    CASE WHEN nav.is_role_peeking_enabled(g.auth_scheme) = 'Y'
        THEN '<b>' || g.auth_scheme || '</b>'
        ELSE          g.auth_scheme
        END ||
    CASE WHEN r.role_name IS NOT NULL
        THEN apex.get_icon('fa-check-square-o', 'Role is active')
        END AS name
FROM p910_auth_schemes g
LEFT JOIN user_roles_assigned r
    ON REPLACE('IS_' || r.role_name, 'IS_IS_', 'IS_') = g.auth_scheme
WHERE g.auth_procedure IS NOT NULL;

