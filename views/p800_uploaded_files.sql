CREATE OR REPLACE VIEW p800_uploaded_files AS
SELECT
    uploader.get_basename(u.file_name) AS list_label,
    --CASE WHEN u.file_name = apex.get_item('$FILE')
    --
    u.created_at || ' ' || u.uploader_id AS supplemental,
    --
    apex.get_page_link (
        in_page_id      => sess.get_page_id(),
        in_names        => 'P800_FILE,P800_SHEET',
        in_values       => u.file_name || ',1'
    ) AS target_url,
    --
    uploader.get_basename(u.file_name) AS file_basename,
    --
    u.file_name,
    u.file_size,
    u.mime_type,
    u.uploader_id,
    u.created_by,
    u.created_at
FROM uploaded_files u
WHERE u.app_id          = sess.get_app_id();

