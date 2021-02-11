prompt --application/pages/page_groups
begin
--   Manifest
--     PAGE GROUPS: 700
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_page_group(
 p_id=>wwv_flow_api.id(64766608684607384)
,p_group_name=>'DASHBOARD'
);
wwv_flow_api.create_page_group(
 p_id=>wwv_flow_api.id(63772249988014549)
,p_group_name=>'INTERNAL'
);
wwv_flow_api.create_page_group(
 p_id=>wwv_flow_api.id(10896609966906033)
,p_group_name=>'OBJECTS'
);
wwv_flow_api.create_page_group(
 p_id=>wwv_flow_api.id(10819719419852508)
,p_group_name=>'UPLOADER'
);
wwv_flow_api.create_page_group(
 p_id=>wwv_flow_api.id(9619968066909198)
,p_group_name=>'USER'
);
wwv_flow_api.component_end;
end;
/
