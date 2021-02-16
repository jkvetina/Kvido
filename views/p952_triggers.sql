CREATE OR REPLACE VIEW p952_triggers AS
SELECT
    t.table_name,
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
    0 AS inserted_,
    0 AS updated_,
    0 AS deleted_,
    0 AS error_,
    0 AS not_mapped_,
    0 AS uploaded_
FROM user_tables t
LEFT JOIN user_triggers g
    ON g.table_name     = t.table_name
LEFT JOIN user_mviews m
    ON m.mview_name     = t.table_name
WHERE t.table_name      NOT LIKE '%\_%$' ESCAPE '\'
    AND t.table_name    NOT IN (
        'LOGS',
        'LOGS_LOBS',
        'LOGS_SETUP',
        'SESSIONS'
    )
    AND m.mview_name    IS NULL;

