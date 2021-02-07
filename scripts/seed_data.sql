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
    --
    -- CLEANUP
    --
    DELETE FROM navigation WHERE app_id = in_app_id;
    --
    -- SHARE BUTTON
    --
    INSERT INTO navigation (app_id, page_id, order#, css_class)
    SELECT in_app_id, -1, 665, 'TRANSPARENT' FROM DUAL;
    --
    -- LEFT/RIGHT splitter
    --
    INSERT INTO navigation (app_id, page_id, order#, css_class)
    SELECT in_app_id, 0, 666, 'hidden' FROM DUAL;        
    --
    -- USER LOGIN/LOGOUT
    --
    INSERT INTO navigation (app_id, page_id, order#)
    SELECT in_app_id, 9999, 999 FROM DUAL;
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

