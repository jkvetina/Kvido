CREATE OR REPLACE FORCE VIEW p910_nav_peek_schemes AS
SELECT
    r.role_id,
    --
    CASE WHEN nav.is_role_peeking_enabled(r.role_id) = 'Y'
        THEN '<b>' || r.role_id || '</b>'
        ELSE          r.role_id
        /*END ||
    CASE WHEN r.role_id IS NOT NULL
        THEN apex.get_icon('fa-check-square-o', 'Role is active')
        */
        END AS name
FROM roles r
UNION ALL
SELECT
    'IS_DEVELOPER' AS role_id,
    --
    CASE WHEN nav.is_role_peeking_enabled('IS_DEVELOPER') = 'Y'
        THEN '<b>' || 'IS_DEVELOPER' || '</b>'
        ELSE          'IS_DEVELOPER'
        END AS name
FROM DUAL;

