CREATE OR REPLACE TRIGGER users__
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW
BEGIN
    tree.log_module('TRIGGER');
    --
    :NEW.user_id        := sess.get_user_name(:NEW.user_id);
    :NEW.updated_by     := COALESCE(sess.get_user_id(), :NEW.updated_by, :NEW.user_id);
    :NEW.updated_at     := SYSDATE;
    --
    tree.update_timer();
END;
/
