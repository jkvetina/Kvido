CREATE OR REPLACE FORCE VIEW p910_nav_overview AS
WITH q AS (
    -- to get correct (hierarchic) order
    SELECT
        q.page_id,
        q.order#    AS seq#
    FROM nav_top_src q
)
SELECT
    n.app_id,
    n.page_id,
    n.parent_id,
    p.page_alias,
    p.page_name,
    p.page_title,
    --
    CASE
        WHEN r.page_id IS NOT NULL
            THEN apex.get_icon('fa-minus-square', 'Remove record from Navigation table')
        END AS status,
    --
    n.order#,
    p.page_css_classes AS css_class,
    n.is_hidden,
    p.page_group,
    --
    CASE WHEN p.page_id IS NOT NULL
        THEN apex.get_developer_page_link(n.page_id)
        END AS page_link,
    --
    CASE WHEN p.authorization_scheme LIKE '%MUST_NOT_BE_PUBLIC_USER%'
        THEN apex.get_icon('fa-check-square', 'MUST_NOT_BE_PUBLIC_USER')
        ELSE p.authorization_scheme
        END AS auth_scheme,
    q.seq#,
    --
    'UD' AS allow_changes  -- U = update, D = delete
FROM navigation n
LEFT JOIN apex_application_pages p
    ON p.application_id         = n.app_id
    AND p.page_id               = n.page_id
LEFT JOIN p910_nav_pages_to_remove r
    ON r.app_id                 = n.app_id
    AND r.page_id               = n.page_id
LEFT JOIN q
    ON q.page_id                = n.page_id
WHERE n.app_id                  = sess.get_app_id()
UNION ALL
SELECT
    p.app_id,
    p.page_id,
    p.parent_id,
    p.page_alias,
    p.page_name,
    p.page_title,
    --
    apex.get_icon('fa-plus-square', 'Create record in Navigation table') AS status,
    --
    p.order#,
    p.css_class,
    p.is_hidden,
    p.page_group,
    --
    apex.get_developer_page_link(p.page_id) AS page_link,
    --
    CASE WHEN p.auth_scheme LIKE '%MUST_NOT_BE_PUBLIC_USER%'
        THEN apex.get_icon('fa-check-square', 'MUST_NOT_BE_PUBLIC_USER')
        ELSE p.auth_scheme
        END AS auth_scheme,
    NULL AS seq#,
    --
    NULL AS allow_changes  -- no changes allowed
FROM p910_nav_pages_to_add p
WHERE p.app_id          = sess.get_app_id();

