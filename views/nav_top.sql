CREATE OR REPLACE FORCE VIEW nav_top AS
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
)
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
        WHEN t.page_id IN (
            curr.page_id, curr.parent_id, curr.root_id
            --, t.group_id
        ) THEN 'YES'
        END AS is_current_list_entry,
    --
    NULL AS image,
    NULL AS image_attribute,
    NULL AS image_alt_attribute,
    --
    CASE
        WHEN t.page_id = 0 THEN 'HIDDEN'
        ELSE t.css_class
        END AS attribute01,
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
    NULL AS attribute06,     -- badge left
    NULL AS attribute07,     -- badge right
    NULL AS attribute08,
    NULL AS attribute09,
    NULL AS attribute10
FROM nav_top_src t
CROSS JOIN curr
WHERE t.order#              > 0
    AND t.is_hidden         IS NULL
    --
    AND 'Y' = nav.is_available(t.page_id)     -- 0.035s
    AND 'Y' = nav.is_visible(sess.get_page_id(), t.page_id)  -- 0.02s
ORDER BY t.order#;
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

