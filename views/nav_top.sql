CREATE OR REPLACE VIEW nav_top AS
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
        WHEN t.page_id = t.curr_page_id     THEN 'YES'
        WHEN t.page_id = t.curr_parent_id   THEN 'YES'
        WHEN t.page_id = t.curr_root_id     THEN 'YES'
        WHEN t.page_id = t.group_id         THEN 'YES'
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
FROM nav_top_src t
CONNECT BY t.app_id         = PRIOR t.app_id
    AND t.parent_id         = PRIOR t.page_id
START WITH t.parent_id      IS NULL
ORDER SIBLINGS BY t.order# NULLS LAST, t.page_id;
--
COMMENT ON TABLE nav_top    IS 'View for top menu, column names cant be changed, they are required by Oracle doc';

