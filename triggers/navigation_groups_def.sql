CREATE OR REPLACE TRIGGER navigation_groups_def
BEFORE INSERT OR UPDATE ON navigation_groups
FOR EACH ROW
BEGIN
    :NEW.app_id         := COALESCE(sess.get_app_id(), :NEW.app_id);
END;
/
