CREATE OR REPLACE VIEW p920_users AS
WITH s AS (
    SELECT
        s.user_id,
        COUNT(*) AS sessions_
    FROM sessions s
    GROUP BY s.user_id
),
l AS (
    SELECT
        l.user_id,
        COUNT(*) AS logs_
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
        AND l.created_at    >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
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
    u.*,
    s.sessions_,
    l.logs_,
    r.roles_,
    u.ROWID AS rid
FROM users u
LEFT JOIN s
    ON s.user_id = u.user_id
LEFT JOIN l
    ON l.user_id = u.user_id
LEFT JOIN r
    ON r.user_id = u.user_id;

