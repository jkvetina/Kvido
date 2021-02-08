prompt --application/shared_components/security/authorizations/nobody_hidden
begin
--   Manifest
--     SECURITY SCHEME: NOBODY - HIDDEN
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_security_scheme(
 p_id=>wwv_flow_api.id(31236197613688358)
,p_name=>'NOBODY - HIDDEN'
,p_scheme_type=>'NATIVE_FUNCTION_BODY'
,p_attribute_01=>'RETURN FALSE;'
,p_error_message=>'AUTH_ERROR'
,p_caching=>'BY_USER_BY_SESSION'
);
wwv_flow_api.component_end;
end;
/
