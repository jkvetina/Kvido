CREATE OR REPLACE FORCE VIEW user_roles_assigned AS
SELECT
    t.role_name AS role_name
FROM (
    SELECT
        'IS_DEVELOPER'          AS role_name,
        auth.is_developer()     AS assigned
    FROM DUAL
    --
    --UNION ALL  -- more roles
    --
) t
WHERE t.assigned = 'Y';

