CREATE OR REPLACE VIEW p850_uploaded_files AS
SELECT
    CASE WHEN u.file_name = apex.get_item('$FILE')
        THEN '<b>' || uploader.get_basename(u.file_name) || '</b>'
        ELSE          uploader.get_basename(u.file_name)
        END AS list_label,
    --
    u.updated_at AS supplemental,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P850_FILE,P850_SHEET',
        in_values       => u.file_name || ',1'
    ) AS target_url,
    --
    u.file_name,
    u.file_size,
    u.mime_type,
    u.uploader_id,
    u.updated_by,
    u.updated_at,
    r.files
FROM uploaded_files u
JOIN (
    SELECT
        u.app_id,
        u.session_id,
        MAX(u.updated_at)   AS updated_at,
        COUNT(*)            AS files
    FROM uploaded_files u
    WHERE u.app_id          = sess.get_app_id()
        AND u.session_id    = sess.get_session_id()
    GROUP BY u.app_id, u.session_id
) r
    ON r.app_id             = u.app_id
    AND r.session_id        = u.session_id
    AND r.updated_at        = u.updated_at;

