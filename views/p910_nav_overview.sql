CREATE OR REPLACE VIEW p910_nav_overview AS
SELECT
    n.app_id,
    n.page_id,
    n.parent_id,
    p.page_alias,
    p.page_name,
    --
    CASE
        WHEN r.page_id IS NOT NULL
            THEN '<span class="fa fa-minus-square" style="color: #666;" title="Remove record from Navigation table"></span>'
        END AS status,
    --
    n.order#,
    n.css_class,
    n.is_hidden,
    p.page_group,
    --
    CASE WHEN p.page_id IS NOT NULL
        THEN '<a href="' ||
            APEX_PAGE.GET_URL (
                p_application   => '4000',
                p_page          => '4500',
                p_session       => apex.get_developer_session_id(),
                p_clear_cache   => '1,4150',
                p_items         => 'FB_FLOW_ID,FB_FLOW_PAGE_ID,F4000_P1_FLOW,F4000_P4150_GOTO_PAGE,F4000_P1_PAGE',
                p_values        => n.app_id || ',' || n.page_id || ',' || n.app_id || ',' || n.page_id || ',' || n.page_id
            ) ||
            '"><span class="fa fa-file-code-o " style="color: #333;" title="Open page in APEX"></span></a>'
        END AS page_link,
    --
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
UNION ALL
SELECT
    a.app_id,
    a.page_id,
    a.parent_id,
    a.page_alias,
    a.page_name,
    --
    '<span class="fa fa-plus-square" style="color: #666;" title="Create record in Navigation table"></span>' AS status,
    --
    a.order#,
    a.css_class,
    a.is_hidden,
    a.page_group,
    --
    '<a href="' ||
    APEX_PAGE.GET_URL (
        p_application   => '4000',
        p_page          => '4500',
        p_session       => apex.get_developer_session_id(),
        p_clear_cache   => '1,4150',
        p_items         => 'FB_FLOW_ID,FB_FLOW_PAGE_ID,F4000_P1_FLOW,F4000_P4150_GOTO_PAGE,F4000_P1_PAGE',
        p_values        => a.app_id || ',' || a.page_id || ',' || a.app_id || ',' || a.page_id || ',' || a.page_id
    ) ||
    '"><span class="fa fa-file-code-o " style="color: #333;" title="Open page in APEX"></span></a>' AS page_link,
    --
    a.auth_scheme
FROM p910_nav_pages_to_add a
WHERE a.app_id          = sess.get_app_id()
    AND a.page_id       BETWEEN 1 AND 999   -- sess.app_min_page AND sess.app_max_page
;
