CREATE OR REPLACE VIEW p910_auth_schemes AS
SELECT
    a.authorization_scheme_name     AS auth_scheme,
    MAX(s.procedure_name)           AS auth_procedure,
    MAX(a.attribute_01)             AS auth_source,
    MAX(p.page_group)               AS page_group,
    MAX(a.error_message)            AS error_message,
    MAX(a.caching)                  AS caching,
    --
    CASE WHEN MAX(s.procedure_name) IS NOT NULL
        THEN '<span class="fa fa-check-square" style="color: #666;" title="Auth procedure exists"></span>'
        END AS status,
    --
    NULLIF(COUNT(p.page_id), 0)     AS pages,
    NULLIF(MAX(u.users), 0)         AS users
FROM apex_application_authorization a
LEFT JOIN apex_application_pages p
    ON p.application_id             = a.application_id
    AND p.authorization_scheme      = a.authorization_scheme_name
LEFT JOIN user_procedures s
    ON s.object_name                = 'AUTH'  -- nav.auth_package
    AND s.procedure_name            = a.authorization_scheme_name
LEFT JOIN (
    SELECT
        'IS_' || u.role_id  AS role_id,
        COUNT(u.role_id)    AS users
    FROM user_roles u
    GROUP BY u.role_id
) u
    ON u.role_id                    = a.authorization_scheme_name
WHERE a.application_id              = sess.get_app_id()
GROUP BY a.authorization_scheme_name;
