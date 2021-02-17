CREATE OR REPLACE VIEW p951_tables AS
WITH c AS (
    -- constraints overview
    SELECT
        c.table_name,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'P' THEN 1 ELSE 0 END), 0) AS pk_,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'U' THEN 1 ELSE 0 END), 0) AS uq_,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'R' THEN 1 ELSE 0 END), 0) AS fk_
    FROM user_constraints c
    WHERE c.constraint_type     IN ('P', 'U', 'R')
        AND c.table_name        = NVL(apex.get_item('$TABLE'), c.table_name)
    GROUP BY c.table_name
),
x AS (
    -- indexes overview
    SELECT
        x.table_name,
        COUNT(x.table_name) AS ix_
    FROM user_indexes x
    WHERE x.index_type          != 'LOB'
        AND x.table_name        = NVL(apex.get_item('$TABLE'), x.table_name)
    GROUP BY x.table_name
),
g AS (
    -- triggers overview
    SELECT
        g.table_name,
        COUNT(g.table_name) AS trg_
    FROM user_triggers g
    WHERE g.table_name          = NVL(apex.get_item('$TABLE'), g.table_name)
    GROUP BY g.table_name
),
p AS (
    SELECT
        p.table_name,
        COUNT(*) AS partitions
    FROM user_tab_partitions p
    WHERE p.table_name          = NVL(apex.get_item('$TABLE'), p.table_name)
    GROUP BY p.table_name
)
SELECT
    t.table_name,
    --
    CASE WHEN c.pk_ IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Table has Primary key')
        END AS pk_,
    --
    CASE WHEN c.uq_ IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Table has Unique key/index')
        END AS uq_,
    --
    c.fk_,
    x.ix_,
    g.trg_,
    --
    p.partitions,
    --
    CASE
        WHEN t.temporary = 'Y'
            THEN apex.get_icon('fa-check-square', '')
        END AS is_temp,
    --
    CASE
        WHEN t.iot_type = 'IOT'
            THEN apex.get_icon('fa-check-square', '')
        END AS is_iot,
    --
    CASE
        WHEN t.row_movement = 'ENABLED'
            THEN apex.get_icon('fa-check-square', 'Row Movement enabled')
        END AS row_mov,
    --
    t.num_rows          AS rows_,
    --
    ROUND(t.num_rows * t.avg_row_len / 1024, 2) AS size_,
    CASE WHEN ROUND(t.blocks * 8, 2) > 0 THEN
        ROUND(t.blocks * 8, 2) - ROUND(t.num_rows * t.avg_row_len / 1024, 2) END AS wasted,
    --
    t.last_analyzed,
    --
    'RECALC' AS action_recalc,
    'SKRINK' AS action_shrink
FROM user_tables t
LEFT JOIN user_mviews m
    ON m.mview_name     = t.table_name
LEFT JOIN c
    ON c.table_name     = t.table_name
LEFT JOIN x
    ON x.table_name     = t.table_name
LEFT JOIN g
    ON g.table_name     = t.table_name
LEFT JOIN p
    ON p.table_name     = t.table_name
WHERE t.table_name      = NVL(apex.get_item('$TABLE'), t.table_name)
    AND t.table_name    NOT LIKE '%\__$' ESCAPE '\'
    AND m.mview_name    IS NULL;

