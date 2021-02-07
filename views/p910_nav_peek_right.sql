CREATE OR REPLACE VIEW p910_nav_peek_right AS
SELECT
    CASE WHEN n.parent_id IS NOT NULL
        THEN '&' || 'nbsp; ' || '&' || 'nbsp; ' || '&' || 'nbsp; '
        END ||
    CASE WHEN n.page_id = apex.get_item('P910_PEEK_PAGE')  -- nav.*
        THEN '<b>' || nav.get_page_label(n.page_name) || '</b>'
        ELSE nav.get_page_label(n.page_name)
        END AS page_name__
FROM nav_top_src n
JOIN (
    SELECT n.page_id
    FROM navigation n
    WHERE n.app_id              = sess.get_app_id()
        AND n.order#            > (
            SELECT n.order#
            FROM navigation n
            WHERE n.app_id      = sess.get_app_id()
                AND n.page_id   = 0
        )
        AND n.parent_id         IS NULL
        AND n.page_id           > 0
) l
    ON l.page_id = NVL(n.parent_id, n.page_id)
--
CONNECT BY n.app_id         = PRIOR n.app_id
    AND n.parent_id         = PRIOR n.page_id
START WITH n.parent_id      IS NULL
ORDER SIBLINGS BY n.order# NULLS LAST, n.page_id;

