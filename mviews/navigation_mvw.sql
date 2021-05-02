--DROP MATERIALIZED VIEW navigation_mvw;
CREATE MATERIALIZED VIEW navigation_mvw
BUILD DEFERRED
REFRESH COMPLETE ON DEMAND
AS
SELECT  -- fake first record to have correct data types
    0   AS page_id,
    0   AS parent_id,
    '-' AS page_alias,
    '-' AS page_name,
    '-' AS page_title,
    '-' AS page_target,
    '-' AS page_onclick,
    '-' AS page_group,
    '-' AS auth_scheme,
    '-' AS css_class,
    '-' AS reset_item,
    '-' AS is_hidden,
    0   AS order#
FROM DUAL
WHERE 1 = 0
UNION ALL
SELECT
    t.page_id,
    t.parent_id,
    t.page_alias,
    t.page_name,
    t.page_title,
    t.page_target,
    t.page_onclick,
    t.page_group,
    t.auth_scheme,
    t.css_class,
    t.reset_item,
    t.is_hidden,
    --
    ROWNUM AS order#
FROM (
    SELECT
        t.page_id,
        t.parent_id,
        t.page_alias,
        t.page_name,
        t.page_title,
        t.page_target,
        t.page_onclick,
        t.page_group,
        t.auth_scheme,
        t.css_class,
        t.reset_item,
        t.is_hidden
    FROM (
        SELECT
            n.app_id,
            n.page_id,
            n.parent_id,
            p.page_alias,
            p.page_name,
            p.page_title,
            NULL                        AS page_target,
            NULL                        AS page_onclick,
            p.page_group,
            p.authorization_scheme      AS auth_scheme,
            --
            p.page_group || ' ' || p.page_css_classes AS css_class,
            --
            i.item_name                 AS reset_item,
            n.order#,
            n.is_hidden
        FROM navigation n
        JOIN apex_application_pages p
            ON p.application_id         = n.app_id
            AND p.page_id               = n.page_id
        LEFT JOIN apex_application_page_items i
            ON i.application_id         = p.application_id
            AND i.page_id               = p.page_id
            AND i.item_name             = 'P' || TO_CHAR(p.page_id) || '_RESET'
        WHERE n.app_id                  = sess.get_app_id()
        --
        UNION ALL
        SELECT
            n.app_id,
            NULL                        AS page_id,
            NULL                        AS parent_id,
            n.page_alias,
            n.page_name,
            n.page_title,
            n.page_target,
            n.page_onclick,
            n.page_group,
            n.auth_scheme,
            n.css_class,
            NULL                        AS reset_item,
            n.order#,
            n.is_hidden
        FROM navigation_extras n
        WHERE n.app_id                  = sess.get_app_id()
    ) t
    CONNECT BY t.app_id         = PRIOR t.app_id
        AND t.parent_id         = PRIOR t.page_id
    START WITH t.parent_id      IS NULL
    ORDER SIBLINGS BY t.order# NULLS LAST, t.page_id
) t;
/*
BEGIN
    sess.create_session('DEV', 700, 910);
    --
    DBMS_SNAPSHOT.REFRESH('NAVIGATION_MVW');   -- 6sec
END;
/
--
SELECT * FROM navigation_mvw;
*/

