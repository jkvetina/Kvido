CREATE OR REPLACE VIEW p851_uploaded_files AS
SELECT
    u.file_name,
    uploader.get_basename(u.file_name) AS basename,
    u.file_size,
    u.mime_type,
    u.uploader_id,
    u.updated_by,
    u.updated_at
FROM uploaded_files u
WHERE (u.app_id, u.session_id, u.updated_at) IN (
    SELECT u.app_id, u.session_id, MAX(u.updated_at) AS updated_at
    FROM uploaded_files u
    WHERE u.app_id          = sess.get_app_id()
        AND u.session_id    = sess.get_session_id()
    GROUP BY u.app_id, u.session_id
);

