CREATE OR REPLACE FORCE VIEW p805_table_columns AS
SELECT
    c.table_name,
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
    c.nullable,
    --
    CASE WHEN c.column_id = 1 THEN 'Y' END AS is_first,
    CASE WHEN LEAD(c.column_id) OVER(PARTITION BY c.table_name ORDER BY c.column_id) IS NULL THEN 'Y' END AS is_last,
    --
    MAX(LENGTH(c.column_name)) OVER(PARTITION BY c.table_name) AS name_length
FROM user_tab_columns c
JOIN user_tables t
    ON t.table_name     = c.table_name
WHERE t.table_name      NOT LIKE '%\__$' ESCAPE '\';

