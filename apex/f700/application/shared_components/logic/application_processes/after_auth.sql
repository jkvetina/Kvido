prompt --application/shared_components/logic/application_processes/after_auth
begin
--   Manifest
--     APPLICATION PROCESS: AFTER_AUTH
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
 p_id=>wwv_flow_api.id(51327090551305329)
,p_process_sequence=>1
,p_process_point=>'AFTER_LOGIN'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'AFTER_AUTH'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'sess.create_session (',
'    in_user_id      => :APP_USER,',
'    in_apply_items  => TRUE',
');'))
,p_process_clob_language=>'PLSQL'
);
wwv_flow_api.component_end;
end;
/
