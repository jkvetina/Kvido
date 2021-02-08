prompt --application/shared_components/logic/application_processes/on_new_instance
begin
--   Manifest
--     APPLICATION PROCESS: ON_NEW_INSTANCE
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
 p_id=>wwv_flow_api.id(51334344862333945)
,p_process_sequence=>12
,p_process_point=>'ON_NEW_INSTANCE'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'ON_NEW_INSTANCE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'sess.create_session (',
'    in_user_id => :APP_USER',
');'))
,p_process_clob_language=>'PLSQL'
);
wwv_flow_api.component_end;
end;
/
