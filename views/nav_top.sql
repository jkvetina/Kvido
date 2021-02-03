CREATE OR REPLACE VIEW nav_top AS
WITH curr AS (
    SELECT
        n.app_id,
        n.page_id,
        n.parent_id,
        sess.get_root_page_id(n.page_id)    AS root_id,
        sess.get_user_id()                  AS user_id,
        sess.get_page_group(n.page_id)      AS page_group
    FROM navigation n
    WHERE n.app_id      = sess.get_app_id()
        AND n.page_id   = sess.get_page_id()
),
t AS (
    SELECT
        n.app_id,
        n.page_id,
        a.page_alias,
        n.icon_name,
        n.css_class,
        i.item_name     AS reset_item,
        n.order#,
        n.parent_id,
        --
        REPLACE(REPLACE(REPLACE(REPLACE(n.label,
            '$CTX:DATE',            TO_CHAR(SYSDATE, 'YYYY-MM-DD')),
            '$CTX:USER_NAME',       curr.user_id),
            '$CTX:ENV_NAME',        'ENV_NAME'),
            '$CTX:',                ''
        ) AS label,
        g.page_id       AS group_id
    FROM navigation n
    CROSS JOIN curr
    LEFT JOIN apex_application_pages a              -- we need LEFT JOIN for pages -1 and 0
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
    CASE WHEN t.icon_name LIKE '{<%' THEN '<span class="fa ' || REGEXP_SUBSTR(t.icon_name, '{.([^}]+)', 1, 1, NULL, 1) || '"></span> &' || 'nbsp; ' END ||
    CASE WHEN t.icon_name LIKE '{!%' THEN '<span class="fa ' || REGEXP_SUBSTR(t.icon_name, '{.([^}]+)', 1, 1, NULL, 1) || '" title="' || t.label || '"></span>' END ||
    CASE WHEN (t.icon_name IS NULL OR t.icon_name NOT LIKE '{!%') THEN t.label END ||
    CASE WHEN t.icon_name LIKE '{>%' THEN ' &' || 'nbsp; <span class="fa ' || REGEXP_SUBSTR(t.icon_name, '{.([^}]+)', 1, 1, NULL, 1) || '"></span>' END AS label,
    --
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
    NULL                    AS attribute10
FROM t
CONNECT BY t.app_id         = PRIOR t.app_id
    AND t.parent_id         = PRIOR t.page_id
START WITH t.parent_id      IS NULL
ORDER SIBLINGS BY t.order#, t.page_id;

