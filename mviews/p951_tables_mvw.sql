--DROP MATERIALIZED VIEW p951_tables;
CREATE MATERIALIZED VIEW p951_tables
BUILD DEFERRED
REFRESH COMPLETE ON DEMAND
AS
WITH s AS (
    -- columns count
    SELECT
        c.table_name,
        COUNT(*) AS cols_
    FROM user_tab_cols c
    GROUP BY c.table_name
),
c AS (
    -- constraints overview
    SELECT
        c.table_name,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'P' THEN 1 ELSE 0 END), 0) AS pk_,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'U' THEN 1 ELSE 0 END), 0) AS uq_,
        NULLIF(SUM(CASE WHEN c.constraint_type = 'R' THEN 1 ELSE 0 END), 0) AS fk_
    FROM user_constraints c
    WHERE c.constraint_type     IN ('P', 'U', 'R')
    GROUP BY c.table_name
),
i AS (
    -- indexes overview
    SELECT
        i.table_name,
        COUNT(i.table_name) AS ix_
    FROM user_indexes i
    WHERE i.index_type          != 'LOB'
    GROUP BY i.table_name
),
g AS (
    -- triggers overview
    SELECT
        g.table_name,
        COUNT(g.table_name) AS trg_
    FROM user_triggers g
    GROUP BY g.table_name
),
p AS (
    -- partitions count
    SELECT
        p.table_name,
        COUNT(*) AS partitions
    FROM user_tab_partitions p
    GROUP BY p.table_name
)
--
SELECT
    t.table_name,
    s.cols_,
    t.num_rows          AS rows_,
    --
    CASE WHEN m.mview_name IS NOT NULL
        THEN apex.get_icon('fa-check-square', 'Materialized view')
        END AS mvw,
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
    i.ix_,
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
    ROUND(t.num_rows * t.avg_row_len / 1024, 0) AS size_,
    CASE WHEN ROUND(t.blocks * 8, 2) > 0 THEN
        ROUND(t.blocks * 8, 2) - ROUND(t.num_rows * t.avg_row_len / 1024, 0) END AS wasted,
    --
    o.last_ddl_time,
    t.last_analyzed,
    --
    c.comments
FROM user_tables t
JOIN user_objects o
    ON o.object_name            = t.table_name
    AND o.object_type           = 'TABLE'
LEFT JOIN user_mviews m                             -- this slows results significantly
    ON m.mview_name             = t.table_name
LEFT JOIN user_tab_comments c
    ON c.table_name             = t.table_name
--
LEFT JOIN s ON s.table_name     = t.table_name
LEFT JOIN c ON c.table_name     = t.table_name
LEFT JOIN i ON i.table_name     = t.table_name
LEFT JOIN g ON g.table_name     = t.table_name
LEFT JOIN p ON p.table_name     = t.table_name
--
WHERE t.table_name              NOT LIKE '%\__$' ESCAPE '\';

