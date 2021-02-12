CREATE OR REPLACE VIEW p850_recent_files AS
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
    u.updated_at
FROM uploaded_files u
LEFT JOIN p850_uploaded_files f
    ON f.file_name      = u.file_name
WHERE u.app_id          = sess.get_app_id()
    AND u.updated_by    = sess.get_user_id()
    AND f.file_name     IS NULL;

