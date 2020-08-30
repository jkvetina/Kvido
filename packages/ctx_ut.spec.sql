CREATE OR REPLACE PACKAGE ctx_ut AS

    -- %suite
    -- %rollback(manual)
    -- %beforeeach(before_each)
    -- %aftereach(after_each)
    -- %beforeall(before_all)
    -- %afterall(after_all)

    PROCEDURE before_all;
    PROCEDURE after_all;
    PROCEDURE before_each;
    PROCEDURE after_each;



    -- %test
    PROCEDURE set_context;
    -- set any app context except user_id

    -- %test
    PROCEDURE set_context#user_id;
    -- setting user_id as context must fail

    -- %test
    --PROCEDURE set_context#date;

    -- %test
    --PROCEDURE get_context;
    -- retrieve context value (string)

    -- %test
    --PROCEDURE get_context_number;
    -- retrieve context number

    -- %test
    PROCEDURE get_context_date;
    -- retrieve context date

    -- %test
    -- %throws(-1841)
    PROCEDURE get_context_date#wrong_format;

    -- %test
    --PROCEDURE set_user_id;
    -- set user_id

    -- %test
    --PROCEDURE get_user_id;
    -- get user_id

    -- %test
    --PROCEDURE get_session_db;

    -- %test
    --PROCEDURE get_client_id;
    -- get client id used in system views

    -- %test
    --PROCEDURE get_payload;

    -- %test
    --PROCEDURE apply_payload;

    -- %test
    PROCEDURE save_contexts;

    -- %test
    PROCEDURE load_contexts;

    -- %test
    PROCEDURE init;

END;
/
