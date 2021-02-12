CREATE OR REPLACE VIEW p860_uploaders_mapping AS
SELECT m.*
FROM uploaders_mapping m
WHERE m.app_id          = sess.get_app_id()
    AND m.uploader_id   = apex.get_item('$TARGET');

