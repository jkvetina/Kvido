CREATE OR REPLACE FORCE VIEW p805_uploaders_possible AS
WITH u AS (
    SELECT
        u.uploader_id,
        MAX(u.is_active)    AS is_active,
        MAX(m.updated_at)   AS updated_at
    FROM uploaders u
    LEFT JOIN uploaders_mapping m
        ON m.app_id         = u.app_id
        AND m.uploader_id   = u.uploader_id
    WHERE u.app_id          = sess.get_app_id()
    GROUP BY u.uploader_id
)
SELECT
    u.uploader_id,
    u.is_active,
    t.object_name           AS table_name,
    --
    r.page_id,
    p.page_title            AS page_name,
    p.page_group,
    r.region_id,
    r.region_name,
    NVL(r.authorization_scheme, p.authorization_scheme) AS auth_scheme,
    --
    --t.last_ddl_time         AS table_changed_at,
    --r.last_updated_on       AS region_changed_at,
    --
    CASE WHEN (u.updated_at IS NULL OR t.last_ddl_time > u.updated_at)
        THEN apex.get_icon('fa-warning', 'Synchronize columns Column Mappings')
        END AS mappings_check,
    --
    CASE
        WHEN t.last_ddl_time > r.last_updated_on
            THEN apex.get_icon('fa-warning', 'Synchronize columns in APEX region')
        END AS region_check,
    --
    CASE
        WHEN (
                e.table_name IS NULL        -- DML Err table missing
                -- @TODO: compare err table columns and data types with real target table
                --OR u$ table missing / wrong columns / old date
                OR s.object_name IS NULL    -- handling procedure not exists                -- @TODO: check stamp, maybe cols
            )
            THEN apex.get_icon('fa-warning', 'Rebuild Uploader')
        END AS action,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P805_REBUILD_UPLOADER,P805_UPLOADER_ID,P805_TABLE_NAME',
        in_values       => 'Y,' || r.static_id || ',' || r.static_id
    ) AS action_link
FROM user_objects t
LEFT JOIN user_tables e
    ON e.table_name         = uploader.get_u$_table_name(t.object_name)
JOIN apex_application_page_regions r
    ON r.application_id     = sess.get_app_id()
    AND r.static_id         = t.object_name
JOIN apex_application_pages p
    ON p.application_id     = r.application_id
    AND p.page_id           = r.page_id
LEFT JOIN u
    ON u.uploader_id        = r.static_id
LEFT JOIN user_objects s
    ON s.object_name        = UPPER(uploader.get_procedure_name(t.object_name))
    AND s.object_type       = 'PROCEDURE'
    AND s.status            = 'VALID'
WHERE t.object_type         IN ('TABLE', 'VIEW');

