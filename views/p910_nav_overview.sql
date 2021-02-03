CREATE OR REPLACE VIEW p910_nav_overview AS
SELECT
    n.app_id,
    n.page_id,
    n.parent_id,
    p.page_alias,
    --
    CASE WHEN r.page_id IS NOT NULL
        THEN '<span class="fa fa-minus-square" style="color: #666;" title=""></span>'
        END AS status,
        --
        -- fa-check-square FOR UPDATED ROWS
        --
    --
    n.order#,
    n.label,
    n.icon_name,
    n.css_class,
    n.is_hidden,
    p.page_group,
    p.page_id                   AS page_link,
    p.authorization_scheme      AS auth_scheme
FROM navigation n
LEFT JOIN apex_application_pages p
    ON p.application_id         = n.app_id
    AND p.page_id               = n.page_id
LEFT JOIN p910_nav_pages_to_remove r
    ON r.app_id                 = n.app_id
    AND r.page_id               = n.page_id
WHERE n.app_id                  = sess.get_app_id()
    AND n.page_id               BETWEEN 1 AND 999  -- sess.app_min_page AND sess.app_max_page
    --
    AND NVL(p.page_group, '-')              = COALESCE(apex.get_item('$PAGE_GROUP'),  p.page_group, '-')
    AND NVL(p.authorization_scheme, '-')    = COALESCE(apex.get_item('$AUTH_SCHEME'), p.authorization_scheme, '-')
UNION ALL
SELECT
    a.app_id,
    a.page_id,
    a.parent_id,
    a.page_alias,
    --
    '<span class="fa fa-plus-square" style="color: #666;" title=""></span>' AS status,
    --
    a.order#,
    a.label,
    a.icon_name,
    a.css_class,
    a.is_hidden,
    a.page_group,
    a.page_link,
    a.auth_scheme
FROM p910_nav_pages_to_add a

ORDER BY 1, 2;
