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
        WHEN e.table_name IS NULL
            THEN apex.get_icon('fa-plus-square', 'Create table to catch DML errors')
        -- WHEN
        --
        -- @TODO: compare err table columns and data types with real target table
        --
        -- @TODO: warning icon on columns mismatch
        --
        END AS err_table
FROM user_objects t
LEFT JOIN user_tables e
    ON e.table_name         = uploader.get_dml_err_table_name(t.object_name)
JOIN apex_application_page_regions r
    ON r.application_id     = sess.get_app_id()
    AND r.static_id         = t.object_name
JOIN apex_application_pages p
    ON p.application_id     = r.application_id
    AND p.page_id           = r.page_id
LEFT JOIN u
    ON u.uploader_id        = r.static_id
WHERE t.object_type         IN ('TABLE', 'VIEW');

