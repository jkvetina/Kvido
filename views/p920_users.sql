CREATE OR REPLACE VIEW p920_users AS
WITH s AS (
    SELECT
        s.user_id,
        COUNT(*) AS sessions_
    FROM sessions s
    GROUP BY s.user_id
)
SELECT
    u.*,
    s.sessions_
    --a.roles_
FROM users u
LEFT JOIN s
    ON s.user_id = u.user_id;

