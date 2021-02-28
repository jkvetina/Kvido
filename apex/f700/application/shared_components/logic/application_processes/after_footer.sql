prompt --application/shared_components/logic/application_processes/after_footer
begin
--   Manifest
--     APPLICATION PROCESS: AFTER_FOOTER
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
 p_id=>wwv_flow_api.id(16171959811957976)
,p_process_sequence=>90
,p_process_point=>'AFTER_FOOTER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'AFTER_FOOTER'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- update timer for log_id stored at page start (before header)',
'FOR c IN (',
'    SELECT s.log_id',
'    FROM sessions s',
'    WHERE s.session_id = sess.get_session_id()',
') LOOP',
'    tree.update_timer(c.log_id);',
'END LOOP;'))
,p_process_clob_language=>'PLSQL'
);
wwv_flow_api.component_end;
end;
/
