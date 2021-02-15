prompt --application/shared_components/logic/application_items/g_date
begin
--   Manifest
--     APPLICATION ITEM: G_DATE
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(12439317969870799)
,p_name=>'G_DATE'
,p_protection_level=>'N'
);
wwv_flow_api.component_end;
end;
/
