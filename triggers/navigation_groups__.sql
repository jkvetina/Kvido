CREATE OR REPLACE TRIGGER navigation_groups__
BEFORE INSERT OR UPDATE ON navigation_groups
FOR EACH ROW
BEGIN
    :NEW.app_id         := COALESCE(NULLIF(sess.get_app_id(), 0), :NEW.app_id);
END;
/
