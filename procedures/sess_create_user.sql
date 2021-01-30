CREATE OR REPLACE PROCEDURE sess_create_user (
    in_username         users.user_id%TYPE
) AS
BEGIN
    tree.log_module(in_username);
    --
    INSERT INTO users (user_id, created_by, created_at, active_at)
    VALUES (
        in_username,
        in_username,
        SYSDATE,
        SYSDATE
    );
    --
    tree.update_timer();
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
    NULL;
END;
/
