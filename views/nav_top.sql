CREATE OR REPLACE VIEW nav_top AS
WITH t AS (
    SELECT
        n.app_id,
        n.page_id,
        a.page_alias,
        n.icon_name,
        n.css_class,
        i.item_name AS reset_item,
        --
        n.order#,
        n.parent_id,
        REPLACE(REPLACE(REPLACE(REPLACE(n.label,
            '$CTX:DATE',            TO_CHAR(SYSDATE, 'YYYY-MM-DD')),
            '$CTX:USER_NAME',       sess.get_user_id()),
            '$CTX:ENV_NAME',        'ENV_NAME'),
            '$CTX:',                ''
        ) AS label
    FROM navigation n
    LEFT JOIN apex_application_pages a
        ON a.application_id         = n.app_id
        AND a.page_id               = n.page_id
        AND a.page_id               > 0
    LEFT JOIN apex_application_page_items i
        ON i.application_id         = a.application_id
        AND i.page_id               = a.page_id
        AND i.item_name             = 'P' || TO_CHAR(a.page_id) || '_RESET'
    WHERE n.app_id                  = sess.get_app_id()
        AND n.is_hidden             IS NULL
        AND NVL(nav.is_available(n.page_id), 'Y') = 'Y'
)
SELECT
    CASE WHEN t.parent_id IS NULL THEN 1 ELSE 2 END AS lvl,
    --
    CASE WHEN t.css_class LIKE '%icon_left%' AND t.icon_name IS NOT NULL THEN '<span class="' || t.icon_name || '"></span> &' || 'nbsp; ' END ||
    CASE WHEN t.css_class LIKE '%icon_only%' AND t.icon_name IS NOT NULL THEN '<span class="' || t.icon_name || '"></span>' END ||
    CASE WHEN (t.css_class IS NULL OR t.css_class NOT LIKE '%icon_only%') THEN t.label END ||
    CASE WHEN t.css_class LIKE '%icon_right%' AND t.icon_name IS NOT NULL THEN ' &' || 'nbsp; <span class="' || t.icon_name || '"></span>' END AS label,
    --
    CASE WHEN t.page_id > 0 THEN
        APEX_PAGE.GET_URL (
            p_page      => NVL(t.page_alias, t.page_id),
            p_items     => CASE WHEN t.reset_item IS NOT NULL THEN t.reset_item END,
            p_values    => CASE WHEN t.reset_item IS NOT NULL THEN 'Y' END
        )
        END AS target,
    --
    CASE WHEN t.page_id = sess.get_root_page_id() THEN 'YES' END AS is_current_list_entry,
    --
    NULL                    AS image,
    NULL                    AS image_attribute,
    NULL                    AS image_alt_attribute,
    NULL                    AS attribute01,
    t.css_class             AS attribute02,             -- li.class
    NULL                    AS attribute03,             -- a.class
    NULL                    AS attribute04,
    NULL                    AS attribute05,
    NULL                    AS attribute06,
    NULL                    AS attribute07,
    NULL                    AS attribute08,
    NULL                    AS attribute09,
    NULL                    AS attribute10
FROM t
CONNECT BY t.app_id         = PRIOR t.app_id
    AND t.parent_id         = PRIOR t.page_id
START WITH t.parent_id      IS NULL
ORDER SIBLINGS BY t.order#;

