CREATE OR REPLACE PROCEDURE sess_create_user (
    in_user_login       users.user_id%TYPE,
    in_user_id          users.user_id%TYPE,
    in_user_name        users.user_name%TYPE
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    tree.log_module(in_user_login, in_user_id, in_user_name);
    --
    BEGIN
        INSERT INTO users (user_id, user_login, is_active, updated_by, updated_at)
        VALUES (
            in_user_id,
            in_user_login,
            'Y',
            in_user_name,
            SYSDATE
        );
    EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    --
    BEGIN
        INSERT INTO user_roles (user_id, role_id, is_active, updated_by, updated_at)
        VALUES (
            in_user_id,
            'USER',
            'Y',
            in_user_name,
            SYSDATE
        );
    EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    --
    COMMIT;
    --
    tree.update_timer();
END;
/
