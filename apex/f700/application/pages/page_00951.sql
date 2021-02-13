prompt --application/pages/page_00951
begin
--   Manifest
--     PAGE: 00951
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_page(
 p_id=>951
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'#fa-table-check Tables'
,p_alias=>'TABLES'
,p_step_title=>'Tables'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(10896609966906033)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_api.id(63770652250014528)
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210213185754'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(11205893952964003)
,p_plug_name=>'Tables'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11205928208964004)
,p_name=>'P951_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(11205893952964003)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11206023560964005)
,p_name=>'P951_TABLE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(11205893952964003)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.component_end;
end;
/
