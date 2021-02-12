CREATE OR REPLACE VIEW p851_recent_files AS
SELECT
    u.file_name,
    uploader.get_basename(u.file_name) AS basename,
    u.file_size,
    u.mime_type,
    u.uploader_id,
    u.updated_by,
    u.updated_at
FROM uploaded_files u
LEFT JOIN p851_uploaded_files f
    ON f.file_name      = u.file_name
WHERE u.app_id          = sess.get_app_id()
    AND u.updated_by    = sess.get_user_id()
    AND f.file_name     IS NULL;

