CREATE OR REPLACE FORCE VIEW p199_user_info AS
SELECT
    u.user_id,
    u.user_login,
    u.user_name,
    u.lang_id       AS lang,
    u.is_active,
    --
    apex.is_developer_y_null(u.user_name) AS is_dev,
    --
    u.updated_by,
    u.updated_at
FROM users u
WHERE u.user_id = sess.get_user_id();

