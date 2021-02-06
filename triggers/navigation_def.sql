CREATE OR REPLACE TRIGGER navigation_def
BEFORE INSERT OR UPDATE ON navigation
FOR EACH ROW
BEGIN
    :NEW.app_id         := COALESCE(NULLIF(sess.get_app_id(), 0), :NEW.app_id);
    :NEW.is_hidden      := NULLIF(:NEW.is_hidden, 'N');
END;
/
