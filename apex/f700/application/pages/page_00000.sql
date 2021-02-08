prompt --application/pages/page_00000
begin
--   Manifest
--     PAGE: 00000
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
 p_id=>0
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'GLOBAL'
,p_alias=>'GLOBAL'
,p_step_title=>'GLOBAL'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(63772249988014549)
,p_protection_level=>'D'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210207113216'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(55550650812191942)
,p_plug_name=>'HELP'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(63687285315014341)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'REGION_POSITION_05'
,p_plug_source=>'<a href="#" style="color: #000;"><span class="fa fa-lg fa-user-md" title=""></span></a>'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_required_role=>wwv_flow_api.id(31236197613688358)
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(55665821815866112)
,p_plug_name=>'Page Items'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>4
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>'SELECT * FROM apex_page_items;'
,p_plug_source_type=>'NATIVE_IR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>'apex.is_developer() AND v(''DEBUG'') = ''YES'''
,p_plug_display_when_cond2=>'PLSQL'
,p_prn_content_disposition=>'ATTACHMENT'
,p_prn_document_header=>'APEX'
,p_prn_units=>'MILLIMETERS'
,p_prn_paper_size=>'A4'
,p_prn_width=>210
,p_prn_height=>297
,p_prn_orientation=>'HORIZONTAL'
,p_prn_page_header_font_color=>'#000000'
,p_prn_page_header_font_family=>'Helvetica'
,p_prn_page_header_font_weight=>'normal'
,p_prn_page_header_font_size=>'12'
,p_prn_page_footer_font_color=>'#000000'
,p_prn_page_footer_font_family=>'Helvetica'
,p_prn_page_footer_font_weight=>'normal'
,p_prn_page_footer_font_size=>'12'
,p_prn_header_bg_color=>'#9bafde'
,p_prn_header_font_color=>'#000000'
,p_prn_header_font_family=>'Helvetica'
,p_prn_header_font_weight=>'normal'
,p_prn_header_font_size=>'10'
,p_prn_body_bg_color=>'#efefef'
,p_prn_body_font_color=>'#000000'
,p_prn_body_font_family=>'Helvetica'
,p_prn_body_font_weight=>'normal'
,p_prn_body_font_size=>'10'
,p_prn_border_width=>.5
,p_prn_page_header_alignment=>'CENTER'
,p_prn_page_footer_alignment=>'CENTER'
);
wwv_flow_api.create_worksheet(
 p_id=>wwv_flow_api.id(55666645984866120)
,p_max_row_count=>'1000000'
,p_show_nulls_as=>'-'
,p_show_search_bar=>'N'
,p_report_list_mode=>'TABS'
,p_show_detail_link=>'N'
,p_owner=>'JKVETINA'
,p_internal_uid=>55666645984866120
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31233495798688334)
,p_db_column_name=>'ITEM_NAME'
,p_display_order=>10
,p_column_identifier=>'A'
,p_column_label=>'Item Name'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31233859272688337)
,p_db_column_name=>'ITEM_VALUE'
,p_display_order=>20
,p_column_identifier=>'B'
,p_column_label=>'Item Value'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_rpt(
 p_id=>wwv_flow_api.id(55686662544277599)
,p_application_user=>'APXWS_DEFAULT'
,p_report_seq=>10
,p_report_alias=>'312342'
,p_status=>'PUBLIC'
,p_is_default=>'Y'
,p_report_columns=>'ITEM_NAME:ITEM_VALUE'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(55666970474866123)
,p_plug_name=>'App Items'
,p_region_template_options=>'#DEFAULT#'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_grid_column_span=>4
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>'SELECT * FROM apex_app_items;'
,p_plug_source_type=>'NATIVE_IR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>'apex.is_developer() AND v(''DEBUG'') = ''YES'''
,p_plug_display_when_cond2=>'PLSQL'
);
wwv_flow_api.create_worksheet(
 p_id=>wwv_flow_api.id(55667086683866124)
,p_max_row_count=>'1000000'
,p_show_nulls_as=>'-'
,p_show_search_bar=>'N'
,p_report_list_mode=>'TABS'
,p_show_detail_link=>'N'
,p_owner=>'JKVETINA'
,p_internal_uid=>55667086683866124
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31234993889688344)
,p_db_column_name=>'ITEM_NAME'
,p_display_order=>10
,p_column_identifier=>'A'
,p_column_label=>'Item Name'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31235362902688345)
,p_db_column_name=>'ITEM_VALUE'
,p_display_order=>20
,p_column_identifier=>'B'
,p_column_label=>'Item Value'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_rpt(
 p_id=>wwv_flow_api.id(55694944457070819)
,p_application_user=>'APXWS_DEFAULT'
,p_report_seq=>10
,p_report_alias=>'312357'
,p_status=>'PUBLIC'
,p_is_default=>'Y'
,p_report_columns=>'ITEM_NAME:ITEM_VALUE'
);
wwv_flow_api.component_end;
end;
/
