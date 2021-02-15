--
-- CREATE APP
--
INSERT INTO apps (app_id, is_active) VALUES (700, 'Y');
COMMIT;



--
-- LOGIN
--
EXEC recompile;
--
BEGIN
    sess.create_session('DEV', 700, 0);  -- user_id, app_id, page_id
END;
/
--
SELECT u.*
FROM users u
ORDER BY 1;
--
/*
DELETE FROM sessions;
DELETE FROM users;
COMMIT;
*/



--
-- INITIAL DATA
--
DECLARE
    in_app_id           CONSTANT navigation.app_id%TYPE := sess.get_app_id();
BEGIN
    DELETE FROM navigation
    WHERE app_id = in_app_id;
    --
    -- LEFT/RIGHT splitter
    --
    INSERT INTO navigation (app_id, page_id, order#, css_class)
    SELECT in_app_id, 0, 666, 'HIDDEN' FROM DUAL;
    --
    -- USER LOGIN/LOGOUT
    --
    INSERT INTO navigation (app_id, page_id, order#)
    SELECT in_app_id, 9999, 999 FROM DUAL;
    --
    COMMIT;
END;
/
DECLARE
    in_app_id           CONSTANT navigation.app_id%TYPE := sess.get_app_id();
BEGIN
    DELETE FROM navigation_extras
    WHERE app_id = in_app_id;
    --
    -- ENV_NAME
    --
    INSERT INTO navigation_extras (app_id, page_alias, page_name, page_title, page_target, page_onclick, order#, css_class)
    VALUES (in_app_id, 'ENV_NAME', '${ENV_NAME}', '', '#', 'return false;', 1, 'ENV_NAME');
    --
    -- SHARE BUTTON
    --
    NULL;
    --
    -- CALENDAR
    --
    INSERT INTO navigation_extras (app_id, page_alias, page_name, order#, css_class)
    VALUES (in_app_id, 'CALENDAR', '<input value="${DATE}" id="NAV_CALENDAR" />', 851, 'CALENDAR');
    --
    COMMIT;
END;
/
--
SELECT n.*
FROM navigation n
WHERE n.app_id = sess.get_app_id()
ORDER BY 1, 2;
--
COMMIT;

