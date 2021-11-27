CREATE OR REPLACE PACKAGE gen AS

    FUNCTION get_width (
        in_table_name           user_tables.table_name%TYPE,
        in_prefix               VARCHAR2
    )
    RETURN PLS_INTEGER;



    PROCEDURE table_args (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    );



    PROCEDURE table_rec (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    );



    PROCEDURE table_where (
        in_table_name           user_tables.table_name%TYPE,
        in_prepend              VARCHAR2                        := '    '
    );



    PROCEDURE handler_call (
        in_procedure_name       user_procedures.procedure_name%TYPE,
        in_prepend              VARCHAR2                                        := '',
        in_app_id               apex_application_pages.application_id%TYPE      := NULL,
        in_page_id              apex_application_pages.page_id%TYPE             := NULL
    );



    PROCEDURE create_handler (
        in_table_name           user_tables.table_name%TYPE,
        in_target_table         user_tables.table_name%TYPE             := NULL,
        in_proc_prefix          user_procedures.procedure_name%TYPE     := 'save_'
    );

END;
/
