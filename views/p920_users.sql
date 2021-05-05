CREATE OR REPLACE FORCE VIEW p920_users AS
WITH x AS (
    SELECT
        c.today,
        c.app_id
    FROM calendar c
    WHERE c.app_id          = sess.get_app_id()
        AND c.today         = app.get_date()
),
s AS (
    SELECT
        s.user_id,
        COUNT(*) AS sessions_
    FROM sessions s
    JOIN x
        ON x.app_id         = s.app_id
        AND x.today         = s.today
    GROUP BY s.user_id
),
l AS (
    SELECT
        l.user_id,
        COUNT(*) AS logs_
    FROM logs l
    JOIN x
        ON x.app_id         = l.app_id
        AND x.today         = l.today
    GROUP BY l.user_id
),
r AS (
    SELECT
        r.user_id,
        NULLIF(COUNT(*), 0) AS roles_
    FROM user_roles r
    WHERE r.app_id          = sess.get_app_id()
    GROUP BY r.user_id
)
SELECT
    u.user_id,
    u.user_login,
    u.user_name,
    u.lang_id,
    u.is_active,
    --
    CASE
        WHEN apex.is_developer_y_null(u.user_id) = 'Y'
            THEN apex.get_icon('fa-check-square', 'Welcome to the club')
            END AS is_dev,
    --
    s.sessions_,
    l.logs_,
    r.roles_,
    --
    u.updated_by,
    u.updated_at,
    u.ROWID             AS rid
FROM users u
LEFT JOIN s ON s.user_id = u.user_id
LEFT JOIN l ON l.user_id = u.user_id
LEFT JOIN r ON r.user_id = u.user_id
WHERE u.user_id NOT IN (
    USER
);

