prompt --application/shared_components/logic/application_processes/on_ajax_callback
begin
--   Manifest
--     APPLICATION PROCESS: ON_AJAX_CALLBACK
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_flow_process(
 p_id=>wwv_flow_api.id(51334911745348330)
,p_process_sequence=>50
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'ON_AJAX_CALLBACK'
,p_process_sql_clob=>'sess.update_session(''AJAX_CALLBACK'');'
,p_process_clob_language=>'PLSQL'
,p_security_scheme=>'MUST_NOT_BE_PUBLIC_USER'
);
wwv_flow_api.component_end;
end;
/
