CREATE OR REPLACE VIEW p951_table_columns AS
SELECT
    c.column_id,
    c.column_name,
    --
    c.data_type ||
    CASE
        WHEN c.data_type LIKE '%CHAR%' OR c.data_type = 'RAW' THEN
            DECODE(NVL(c.char_length, 0), 0, '',
                '(' || c.char_length || DECODE(c.char_used, 'C', ' CHAR', '') || ')'
            )
        WHEN c.data_type = 'NUMBER' THEN
            DECODE(NVL(c.data_precision || c.data_scale, 0), 0, '',
                DECODE(NVL(c.data_scale, 0), 0, '(' || c.data_precision || ')',
                    '(' || c.data_precision || ',' || c.data_scale || ')'
                )
            )
        END AS data_type,
    --
    n.pk_,
    n.uq_,
    n.fk_,              -- @TODO: not rows just use constraint #
    --
    NULLIF(n.ch_ - CASE WHEN c.nullable = 'N' THEN 1 ELSE 0 END, 0) AS ch_,
    --
    CASE WHEN c.nullable = 'N'
        THEN apex.get_icon('fa-check-square', 'Column is mandatory')
        END AS nn,
    --
    CASE WHEN c.data_default IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Column has default value')
        END AS default_,
    --
    m.comments,
    --
    apex.get_icon('fa-database-search', 'Show column dependencies') AS dep
FROM user_tab_columns c
JOIN user_tables t
    ON t.table_name     = c.table_name
LEFT JOIN (
    SELECT
        m.table_name,
        m.column_name,
        NULLIF(SUM(CASE WHEN n.constraint_type = 'P' THEN 1 ELSE 0 END), 0) AS pk_,
        NULLIF(SUM(CASE WHEN n.constraint_type = 'R' THEN 1 ELSE 0 END), 0) AS fk_,
        NULLIF(SUM(CASE WHEN n.constraint_type = 'U' THEN 1 ELSE 0 END), 0) AS uq_,
        NULLIF(SUM(CASE WHEN n.constraint_type = 'C' THEN 1 ELSE 0 END), 0) AS ch_
    FROM user_cons_columns m
    JOIN user_constraints n
        ON n.constraint_name    = m.constraint_name
        AND n.constraint_type   IN ('P', 'R', 'U', 'C')
    WHERE m.table_name          = apex.get_item('$TABLE')
    GROUP BY m.table_name, m.column_name
) n
    ON n.table_name     = c.table_name
    AND n.column_name   = c.column_name
LEFT JOIN user_col_comments m
    ON m.table_name     = c.table_name
    AND m.column_name   = c.column_name
WHERE t.table_name      = apex.get_item('$TABLE');

