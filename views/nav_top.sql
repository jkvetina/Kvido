CREATE OR REPLACE VIEW nav_top AS
WITH curr AS (
    SELECT
        n.app_id,
        n.page_id,
        n.parent_id,
        sess.get_root_page_id(n.page_id)    AS root_id,
        sess.get_page_group(n.page_id)      AS page_group
    FROM navigation n
    WHERE n.app_id      = sess.get_app_id()
        AND n.page_id   = COALESCE(nav.get_peeked_page_id(), sess.get_page_id())
),
t AS (
    SELECT
        n.app_id,
        n.page_id,
        n.parent_id,
        a.page_alias,
        a.page_name,
        a.authorization_scheme      AS auth_scheme,
        n.css_class,
        i.item_name                 AS reset_item,
        g.page_id                   AS group_id,
        n.order#
    FROM navigation n
    CROSS JOIN curr
    LEFT JOIN apex_application_pages a                  -- left join needed for pages <= 0
        ON a.application_id         = n.app_id
        AND a.page_id               = n.page_id
        AND a.page_id               > 0
    LEFT JOIN apex_application_page_items i
        ON i.application_id         = a.application_id
        AND i.page_id               = a.page_id
        AND i.item_name             = 'P' || TO_CHAR(a.page_id) || '_RESET'
    LEFT JOIN navigation_groups g
        ON g.app_id                 = n.app_id
        AND g.page_id               = n.page_id
        AND g.page_group            = sess.get_page_group(curr.page_id)
    WHERE n.app_id                  = curr.app_id
        AND n.is_hidden             IS NULL
        --
        AND 'Y' = nav.is_available(n.page_id)
        AND 'Y' = nav.is_visible(curr.page_id, n.page_id)
        --
        AND (a.page_id IS NOT NULL OR n.page_id < 1 OR n.page_id > 999)
)
SELECT
    CASE WHEN t.parent_id IS NULL THEN 1 ELSE 2 END AS lvl,
    --
    CASE
        WHEN t.page_id > 0 THEN nav.get_page_label(t.page_name)
        WHEN t.page_id = 0 THEN '</li></ul><ul class="empty"></ul><ul><li>'
        ELSE t.page_name END AS label,
    CASE WHEN t.page_id > 0 THEN
        APEX_PAGE.GET_URL (
            p_page      => NVL(t.page_alias, t.page_id),
            p_items     => CASE WHEN t.reset_item IS NOT NULL THEN t.reset_item END,
            p_values    => CASE WHEN t.reset_item IS NOT NULL THEN 'Y' END
        )
        END AS target,
    --
    CASE        
        WHEN t.page_id = (SELECT page_id        FROM curr)  THEN 'YES'
        WHEN t.page_id = (SELECT parent_id      FROM curr)  THEN 'YES'
        WHEN t.page_id = (SELECT root_id        FROM curr)  THEN 'YES'
        WHEN t.page_id = t.group_id                         THEN 'YES'
        END AS is_current_list_entry,
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
    NULL                    AS attribute10,
    --
    t.page_id,
    t.parent_id,
    t.auth_scheme,
    --
    REPLACE(RPAD(' ', (LEVEL - 1) * 4, ' '), ' ', '&' || 'nbsp; ') || t.page_name AS label__
FROM t
CONNECT BY t.app_id         = PRIOR t.app_id
    AND t.parent_id         = PRIOR t.page_id
START WITH t.parent_id      IS NULL
ORDER SIBLINGS BY t.order# NULLS LAST, t.page_id;
