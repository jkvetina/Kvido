CREATE OR REPLACE FORCE VIEW p935_grants AS
SELECT
    r.privilege,
    r.role,
    NULL                AS user_id,
    --
    CASE WHEN s.privilege IS NOT NULL
        THEN apex.get_icon('fa-check-square', '')
        END AS is_active,
    --
    CASE WHEN r.inherited = 'YES'
        THEN apex.get_icon('fa-check-square', '')
        END AS inherited,
    --
    CASE WHEN r.admin_option = 'YES'
        THEN apex.get_icon('fa-check-square', '')
        END AS admin_option
FROM role_sys_privs r
LEFT JOIN session_privs s
    ON s.privilege      = r.privilege
UNION ALL
SELECT
    u.privilege,
    NULL                AS role,
    u.username          AS user_id,
    --
    CASE WHEN s.privilege IS NOT NULL
        THEN apex.get_icon('fa-check-square', '')
        END AS is_active,
    --
    CASE WHEN u.inherited = 'YES'
        THEN apex.get_icon('fa-check-square', '')
        END AS inherited,
    --
    CASE WHEN u.admin_option = 'YES'
        THEN apex.get_icon('fa-check-square', '')
        END AS admin_option
FROM user_sys_privs u
LEFT JOIN session_privs s
    ON s.privilege      = u.privilege
ORDER BY 1;

