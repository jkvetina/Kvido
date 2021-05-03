prompt --application/shared_components/security/authentications/open_door_testing_only
begin
--   Manifest
--     AUTHENTICATION: OPEN_DOOR (TESTING ONLY)
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_authentication(
 p_id=>wwv_flow_api.id(104393079175937346)
,p_name=>'OPEN_DOOR (TESTING ONLY)'
,p_scheme_type=>'NATIVE_OPEN_DOOR'
,p_post_auth_process=>'sess.create_session'
,p_use_secure_cookie_yn=>'N'
,p_ras_mode=>0
);
wwv_flow_api.component_end;
end;
/
