CREATE OR REPLACE FORCE VIEW p952_triggers AS
WITH r AS (
    SELECT
        l.module_name,
        SUM(TO_NUMBER(REGEXP_SUBSTR(l.arguments, '^[[]"INSERTED:(\d+)"', 1, 1, NULL, 1))) AS inserted_,
        SUM(TO_NUMBER(REGEXP_SUBSTR(l.arguments, '^[[]"UPDATED:(\d+)"',  1, 1, NULL, 1))) AS updated_,
        SUM(TO_NUMBER(REGEXP_SUBSTR(l.arguments, '^[[]"DELETED:(\d+)"',  1, 1, NULL, 1))) AS deleted_
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
        AND l.created_at    >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
        AND l.flag          = 'R'
        AND l.action_name   = 'TRIGGER'
        AND l.module_name   = CASE WHEN apex.get_item('$TABLE') IS NOT NULL THEN apex.get_item('$TABLE') || '__' ELSE l.module_name END
        AND l.arguments     IS NOT NULL
    GROUP BY l.module_name
),
m AS (
    SELECT
        l.module_name,
        COUNT(l.log_id)     AS calls_
    FROM logs l
    WHERE l.app_id          = sess.get_app_id()
        AND l.created_at    >= app.get_date()
        AND l.created_at    <  app.get_date() + 1
        AND l.flag          = 'M'
        AND l.action_name   = 'TRIGGER'
        AND l.module_name   = CASE WHEN apex.get_item('$TABLE') IS NOT NULL THEN apex.get_item('$TABLE') || '__' ELSE l.module_name END
    GROUP BY l.module_name
)
SELECT
    t.table_name,
    g.trigger_name,
    --
    CASE
        WHEN g.trigger_name = t.table_name || '__'  -- get_trigger_name()
            AND g.trigger_type = 'COMPOUND'
        THEN apex.get_icon('fa-check-square', '')
        END AS trigger_present,
    --
    CASE
        WHEN g.triggering_event     = 'INSERT OR UPDATE OR DELETE'
            AND g.before_statement  = 'YES'
            AND g.before_row        = 'YES'
            AND g.after_row         = 'YES'
            AND g.after_statement   = 'YES'
            AND g.status            = 'ENABLED'
        THEN apex.get_icon('fa-check-square', '')
        END AS trigger_valid,
    --
    m.calls_,
    r.inserted_,
    r.updated_,
    r.deleted_,
    0 AS error_,
    0 AS not_mapped_,
    --
    apex.get_icon('fa-database', 'Show table details') AS table_
FROM user_tables t
LEFT JOIN user_triggers g
    ON g.table_name     = t.table_name
LEFT JOIN user_mviews v
    ON v.mview_name     = t.table_name
LEFT JOIN m
    ON m.module_name    = g.trigger_name
LEFT JOIN r
    ON r.module_name    = g.trigger_name
WHERE t.table_name      NOT LIKE '%\_%$' ESCAPE '\'
    AND t.table_name    NOT IN (
        'LOGS',
        'LOGS_LOBS',
        'LOGS_SETUP',
        'LOGS_EVENTS',
        'SESSIONS'
    )
    AND t.table_name    = NVL(apex.get_item('$TABLE'), t.table_name)
    AND v.mview_name    IS NULL;

