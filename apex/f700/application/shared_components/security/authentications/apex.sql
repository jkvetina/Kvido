prompt --application/shared_components/security/authentications/apex
begin
--   Manifest
--     AUTHENTICATION: APEX
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
 p_id=>wwv_flow_api.id(65698087598810744)
,p_name=>'APEX'
,p_scheme_type=>'NATIVE_APEX_ACCOUNTS'
,p_use_secure_cookie_yn=>'N'
,p_ras_mode=>0
);
wwv_flow_api.component_end;
end;
/
