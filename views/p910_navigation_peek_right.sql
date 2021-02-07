CREATE OR REPLACE VIEW p910_nav_right AS
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
    AND n.page_id           > 0;
