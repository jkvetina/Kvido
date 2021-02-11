CREATE OR REPLACE VIEW nav_top AS
SELECT
    CASE WHEN t.parent_id IS NULL THEN 1 ELSE 2 END AS lvl,
    --
    CASE
        WHEN t.page_id = 0
            -- a trick to split nav menu to left and right
            THEN '</li></ul><ul class="EMPTY"></ul><ul><li class="HIDDEN" style="display: none;">'
        WHEN t.page_id IS NULL AND t.page_target IS NULL AND t.page_onclick IS NULL
            THEN NULL
        ELSE nav.get_page_label(t.page_name)
        END AS label,
    CASE
        WHEN t.page_id > 0
            THEN APEX_PAGE.GET_URL (
                p_page      => NVL(t.page_alias, t.page_id),
                p_items     => CASE WHEN t.reset_item IS NOT NULL THEN t.reset_item END,
                p_values    => CASE WHEN t.reset_item IS NOT NULL THEN 'Y' END
            )
        ELSE NVL(t.page_target, '#')
        END AS target,
    --
    CASE        
        WHEN t.page_id IN (t.curr_page_id, t.curr_parent_id, t.curr_root_id, t.group_id) THEN 'YES'
        END AS is_current_list_entry,
    --
    NULL                    AS image,
    NULL                    AS image_attribute,
    NULL                    AS image_alt_attribute,
    --
    t.css_class             AS attribute01,
    --
    CASE
        WHEN t.page_id IS NULL AND t.page_target IS NULL
            THEN app.manipulate_page_label(t.page_name)
        END AS attribute02,                     -- prepend link with element
    --
    CASE
        WHEN t.page_id IS NULL AND t.page_target IS NULL AND t.page_onclick IS NULL
            -- hide link
            THEN 'HIDDEN" style="display: none;'
        END AS attribute03,                     -- a.class
    --
    CASE
        WHEN t.page_id = 9999
            THEN 'Logout'
            ELSE t.page_title
            END AS attribute04,                 -- a.title
    --
    CASE
        WHEN t.page_onclick IS NOT NULL
            THEN 'javascript:{' || t.page_onclick || '}'
        END AS attribute05,                     -- javascript action
    --
    NULL                    AS attribute06,     -- badge left
    --
    CASE
        WHEN b.badge IS NOT NULL
            THEN '<span class="BADGE">' || b.badge || '</span>'
        END AS attribute07,                     -- badge right
    --
    NULL                    AS attribute08,
    NULL                    AS attribute09,
    NULL                    AS attribute10
FROM nav_top_src t
LEFT JOIN nav_badges b
    ON (b.page_id           = t.page_id
        OR b.page_alias     = t.page_alias
    )
WHERE t.is_hidden           IS NULL
    --
    AND 'Y' = nav.is_available(t.page_id)
    AND 'Y' = nav.is_visible(t.curr_page_id, t.page_id)
    --
CONNECT BY t.app_id         = PRIOR t.app_id
    AND t.parent_id         = PRIOR t.page_id
START WITH t.parent_id      IS NULL
ORDER SIBLINGS BY t.order# NULLS LAST, t.page_id;
--
COMMENT ON TABLE nav_top                IS 'View for top menu, column names cant be changed, they are required by Oracle doc';
--
COMMENT ON COLUMN nav_top.attribute01   IS '<li class="...">';
COMMENT ON COLUMN nav_top.attribute02   IS '<li>...<a>';
COMMENT ON COLUMN nav_top.attribute03   IS '<a class="..."';
COMMENT ON COLUMN nav_top.attribute04   IS '<a title="..."';
COMMENT ON COLUMN nav_top.attribute05   IS '<a ...>  // javascript onclick';
COMMENT ON COLUMN nav_top.attribute06   IS '<a>... #TEXT</a>';
COMMENT ON COLUMN nav_top.attribute07   IS '<a>#TEXT ...</a>';
COMMENT ON COLUMN nav_top.attribute08   IS '</a>...';

