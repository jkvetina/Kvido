CREATE OR REPLACE TRIGGER navigation_def
BEFORE INSERT OR UPDATE ON navigation
FOR EACH ROW
BEGIN
    :NEW.app_id         := COALESCE(sess.get_app_id(), :NEW.app_id);
END;
/
