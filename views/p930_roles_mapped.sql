CREATE OR REPLACE FORCE VIEW p930_roles_mapped AS
WITH a AS (
    SELECT
        a.authorization_scheme_name         AS role_id,
        MAX(a.attribute_01)                 AS auth_source,
        MAX(a.error_message)                AS error_message,
        MAX(a.caching)                      AS caching,
        COUNT(p.page_id)                    AS pages
    FROM apex_application_authorization a
    LEFT JOIN apex_application_pages p
        ON p.application_id                 = a.application_id
        AND p.authorization_scheme          = a.authorization_scheme_name
    WHERE a.application_id                  = sess.get_app_id()
        AND a.authorization_scheme_name     NOT LIKE 'NOBODY%'
    GROUP BY a.authorization_scheme_name
),
r AS (
    SELECT a.*
    FROM a
    UNION ALL
    SELECT r.role_id, NULL, NULL, NULL, NULL
    FROM roles r
    LEFT JOIN a
        ON a.role_id            = r.role_id
    WHERE r.app_id              = sess.get_app_id()
        AND a.role_id           IS NULL
)
SELECT
    r.role_id,
    --
    NULLIF(u.users, 0)          AS users,
    NULLIF(r.pages, 0)          AS pages,
    --
    CASE WHEN s.procedure_name IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Auth procedure exists')
        END AS status,
    --
    s.procedure_name            AS auth_procedure,
    r.auth_source,
    r.caching,
    r.error_message
FROM r
LEFT JOIN user_procedures s
    ON s.object_name            = 'AUTH'  -- nav.auth_package
    AND s.procedure_name        = r.role_id
LEFT JOIN (
    SELECT
        u.role_id               AS role_id,
        COUNT(u.role_id)        AS users
    FROM user_roles u
    GROUP BY u.role_id
) u
    ON u.role_id                = r.role_id;

