prompt --application/shared_components/navigation/lists/user_interface
begin
--   Manifest
--     LIST: User Interface
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(63885641783014959)
,p_name=>'User Interface'
,p_list_status=>'PUBLIC'
,p_required_patch=>wwv_flow_api.id(63769115224014517)
);
wwv_flow_api.component_end;
end;
/
