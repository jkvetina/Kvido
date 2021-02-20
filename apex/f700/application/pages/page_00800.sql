prompt --application/pages/page_00800
begin
--   Manifest
--     PAGE: 00800
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
 p_id=>800
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'#fa-file-excel-o'
,p_alias=>'UPLOADER'
,p_step_title=>'Uploader'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(10819719419852508)
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// move submit button to better place',
'$(''#SUBMIT_UPLOAD'').appendTo($(''#P800_UPLOAD_DROPZONE span.apex-item-filedrop-action'').parent());',
'',
'// prevent another file popup on submit',
'$(''#SUBMIT_UPLOAD'').on(''click'', function(event) {',
'    event.preventDefault();',
'    return false;',
'});',
''))
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#SUBMIT_UPLOAD {',
'    margin: -3.2rem 0 0 18rem;',
'}',
''))
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210220132356'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(25071177918009654)
,p_plug_name=>'File Info'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>40
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT f.*',
'FROM p800_uploaded_files f',
'WHERE f.file_name = apex.get_item(''$FILE'');',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_FILE'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35387743581829181)
,p_plug_name=>'Uploaded Files'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_plug_grid_column_span=>3
,p_plug_grid_column_css_classes=>'NO_ARROWS'
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT f.*',
'FROM p800_uploaded_files f',
'WHERE f.created_at >= TRUNC(SYSDATE)',
'ORDER BY f.created_at DESC, f.file_basename;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497432343984053)
,p_plug_name=>'File Sheets'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>50
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT s.*',
'FROM p800_uploaded_file_sheets s',
'ORDER BY s.sheet_id;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_FILE'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497535560984054)
,p_plug_name=>'Sheet Content'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>60
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT s.*',
'FROM p800_uploaded_sheet_content s;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHEET'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_08=>'COUNT_'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497554466984055)
,p_plug_name=>'Sheet Columns Mapping'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>110
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM p800_sheet_columns_mapping;',
''))
,p_plug_source_type=>'NATIVE_IG'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHOW_COLS'
,p_prn_content_disposition=>'ATTACHMENT'
,p_prn_document_header=>'APEX'
,p_prn_units=>'MILLIMETERS'
,p_prn_paper_size=>'A4'
,p_prn_width=>297
,p_prn_height=>210
,p_prn_orientation=>'HORIZONTAL'
,p_prn_page_header=>'Sheet Columns Mapping'
,p_prn_page_header_font_color=>'#000000'
,p_prn_page_header_font_family=>'Helvetica'
,p_prn_page_header_font_weight=>'normal'
,p_prn_page_header_font_size=>'12'
,p_prn_page_footer_font_color=>'#000000'
,p_prn_page_footer_font_family=>'Helvetica'
,p_prn_page_footer_font_weight=>'normal'
,p_prn_page_footer_font_size=>'12'
,p_prn_header_bg_color=>'#EEEEEE'
,p_prn_header_font_color=>'#000000'
,p_prn_header_font_family=>'Helvetica'
,p_prn_header_font_weight=>'bold'
,p_prn_header_font_size=>'10'
,p_prn_body_bg_color=>'#FFFFFF'
,p_prn_body_font_color=>'#000000'
,p_prn_body_font_family=>'Helvetica'
,p_prn_body_font_weight=>'normal'
,p_prn_body_font_size=>'10'
,p_prn_border_width=>.5
,p_prn_page_header_alignment=>'CENTER'
,p_prn_page_footer_alignment=>'CENTER'
,p_prn_border_color=>'#666666'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<span class="timing">#TIMING#s</span>',
''))
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(13645508143013502)
,p_name=>'APEX$ROW_ACTION'
,p_item_type=>'NATIVE_ROW_ACTION'
,p_display_sequence=>20
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(13645620573013503)
,p_name=>'APEX$ROW_SELECTOR'
,p_item_type=>'NATIVE_ROW_SELECTOR'
,p_display_sequence=>10
,p_attribute_01=>'Y'
,p_attribute_02=>'Y'
,p_attribute_03=>'N'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(13645822226013505)
,p_name=>'ALLOW_CHANGES'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'ALLOW_CHANGES'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>150
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(13646165680013508)
,p_name=>'STATUS_MAPPED'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'STATUS_MAPPED'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>40
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_is_primary_key=>false
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(13646242178013509)
,p_name=>'STATUS_MISSING'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'STATUS_MISSING'
,p_data_type=>'NUMBER'
,p_is_query_only=>true
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>50
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_is_primary_key=>false
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25071798561009660)
,p_name=>'COLUMN_ID'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'COLUMN_ID'
,p_data_type=>'NUMBER'
,p_is_query_only=>true
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'Source #'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>60
,p_value_alignment=>'RIGHT'
,p_attribute_03=>'right'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>true
,p_include_in_export=>true
,p_readonly_condition_type=>'ALWAYS'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25071981582009662)
,p_name=>'DATA_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_TYPE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Data Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>70
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>97
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_readonly_condition_type=>'ALWAYS'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25507871117061614)
,p_name=>'SOURCE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'SOURCE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Source Column'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>80
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>64
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25507981583061615)
,p_name=>'TARGET_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TARGET_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Target Column'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>100
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>30
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>true
,p_duplicate_value=>true
,p_include_in_export=>true
,p_readonly_condition_type=>'ALWAYS'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25508080207061616)
,p_name=>'TARGET_DATA_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TARGET_DATA_TYPE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Target Data Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>110
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>211
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_readonly_condition_type=>'ALWAYS'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25508198939061617)
,p_name=>'IS_KEY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IS_KEY'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Is Key'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>120
,p_value_alignment=>'CENTER'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_escape_on_http_output=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25508205424061618)
,p_name=>'IS_NN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IS_NN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Is Nn'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>130
,p_value_alignment=>'CENTER'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_escape_on_http_output=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25508366263061619)
,p_name=>'OVERWRITE_VALUE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'OVERWRITE_VALUE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Overwrite Value'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>140
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>256
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_security_scheme=>wwv_flow_api.id(63770652250014528)
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25508892311061624)
,p_name=>'STATUS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'STATUS'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Status'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>30
,p_value_alignment=>'CENTER'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_escape_on_http_output=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25509395252061629)
,p_name=>'TARGET_COLUMN_ID'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TARGET_COLUMN_ID'
,p_data_type=>'NUMBER'
,p_is_query_only=>true
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'Target #'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>90
,p_value_alignment=>'RIGHT'
,p_attribute_03=>'right'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_include_in_export=>true
,p_readonly_condition_type=>'ALWAYS'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(25071453518009657)
,p_internal_uid=>25071453518009657
,p_is_editable=>true
,p_edit_operations=>'u'
,p_edit_row_operations_column=>'ALLOW_CHANGES'
,p_update_authorization_scheme=>wwv_flow_api.id(63770652250014528)
,p_lost_update_check_type=>'VALUES'
,p_submit_checked_rows=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_select_first_row=>false
,p_pagination_type=>'SET'
,p_show_total_row_count=>true
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SAVE'
,p_enable_save_public_report=>false
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>true
,p_download_formats=>'CSV:HTML:XLSX:PDF'
,p_enable_mail_download=>true
,p_fixed_header=>'PAGE'
,p_show_icon_view=>false
,p_show_detail_view=>false
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function(config) {',
'    return unified_ig_toolbar(config, '''');',
'}',
''))
);
wwv_flow_api.create_ig_report(
 p_id=>wwv_flow_api.id(25498659902916084)
,p_interactive_grid_id=>wwv_flow_api.id(25071453518009657)
,p_static_id=>'120623'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(25498817486916085)
,p_report_id=>wwv_flow_api.id(25498659902916084)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(13991443121063)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>0
,p_column_id=>wwv_flow_api.id(13645508143013502)
,p_is_visible=>true
,p_is_frozen=>true
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(30197951254887)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>11
,p_column_id=>wwv_flow_api.id(13645822226013505)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(13733900283881626)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>12
,p_column_id=>wwv_flow_api.id(13646165680013508)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(13739824615893342)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>13
,p_column_id=>wwv_flow_api.id(13646242178013509)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25501180302916101)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(25071798561009660)
,p_is_visible=>false
,p_is_frozen=>false
,p_width=>90
,p_sort_order=>1
,p_sort_direction=>'ASC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25502902793916108)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(25071981582009662)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>179
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25513858926067064)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(25507871117061614)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>195
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25514707565067068)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(25507981583061615)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>199
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25515636725067073)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(25508080207061616)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>154
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25516537322067077)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>8
,p_column_id=>wwv_flow_api.id(25508198939061617)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>67
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25517405309067081)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>9
,p_column_id=>wwv_flow_api.id(25508205424061618)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>62
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25518354354067085)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>11
,p_column_id=>wwv_flow_api.id(25508366263061619)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>569
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25656925791325866)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(25508892311061624)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>69
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25681220724535791)
,p_view_id=>wwv_flow_api.id(25498817486916085)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(25509395252061629)
,p_is_visible=>false
,p_is_frozen=>false
,p_width=>70
,p_sort_order=>2
,p_sort_direction=>'ASC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497681472984056)
,p_plug_name=>'Sheet Data'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>130
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHOW_DATA'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497845337984057)
,p_plug_name=>'Not Mapped Rows'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>140
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHOW_NOT_MAPPED'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35497855932984058)
,p_plug_name=>'Rows with Errors'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>150
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHOW_ERRORS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(35499407546984073)
,p_plug_name=>'Target'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>70
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT t.*',
'FROM p800_uploaded_targets t;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_SHEET'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(37673622004032103)
,p_plug_name=>'Preview'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>80
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_plug_source_type=>'NATIVE_JET_CHART'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P800_PREVIEW'
);
wwv_flow_api.create_jet_chart(
 p_id=>wwv_flow_api.id(13451513043622309)
,p_region_id=>wwv_flow_api.id(37673622004032103)
,p_chart_type=>'donut'
,p_height=>'300'
,p_animation_on_display=>'none'
,p_animation_on_data_change=>'none'
,p_data_cursor=>'auto'
,p_data_cursor_behavior=>'auto'
,p_hover_behavior=>'dim'
,p_value_format_type=>'decimal'
,p_value_decimal_places=>0
,p_value_format_scaling=>'none'
,p_fill_multi_series_gaps=>false
,p_tooltip_rendered=>'Y'
,p_show_series_name=>false
,p_show_group_name=>false
,p_show_value=>false
,p_show_label=>false
,p_show_row=>false
,p_show_start=>false
,p_show_end=>false
,p_show_progress=>false
,p_show_baseline=>false
,p_legend_rendered=>'off'
,p_pie_other_threshold=>0
,p_pie_selection_effect=>'highlight'
,p_show_gauge_value=>false
);
wwv_flow_api.create_jet_chart_series(
 p_id=>wwv_flow_api.id(13452041869622312)
,p_chart_id=>wwv_flow_api.id(13451513043622309)
,p_seq=>10
,p_name=>'Series 1'
,p_data_source_type=>'SQL'
,p_data_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT 30 AS rows_, ''INS'' AS type_ FROM DUAL UNION ALL',
'SELECT 20 AS rows_, ''UPD'' AS type_ FROM DUAL UNION ALL',
'SELECT 5  AS rows_, ''DEL'' AS type_ FROM DUAL UNION ALL',
'SELECT 10 AS rows_, ''ERR'' AS type_ FROM DUAL UNION ALL',
'SELECT 5  AS rows_, ''KEY'' AS type_ FROM DUAL;'))
,p_items_value_column_name=>'ROWS_'
,p_items_label_column_name=>'TYPE_'
,p_items_short_desc_column_name=>'TYPE_'
,p_items_label_rendered=>true
,p_items_label_position=>'auto'
,p_items_label_display_as=>'VALUE'
,p_link_target=>'f?p=&APP_ID.:800:&SESSION.::&DEBUG.::P800_SHOW_RESULT:&TYPE_.'
,p_link_target_type=>'REDIRECT_PAGE'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(46429087864913333)
,p_plug_name=>'Upload File &P800_TARGET_NAME.'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NULL'
,p_plug_display_when_condition=>'P800_FILE'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13440902717622269)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(46429087864913333)
,p_button_name=>'SUBMIT'
,p_button_static_id=>'SUBMIT_UPLOAD'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Submit'
,p_button_position=>'BELOW_BOX'
,p_button_execute_validations=>'N'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13436940974622234)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(35499407546984073)
,p_button_name=>'CHANGE_TARGET'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-sequence" title="Show more targets"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:800:&SESSION.::&DEBUG.::P800_FILE,P800_SHEET,P800_TARGET:&P800_FILE.,&P800_SHEET.,'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13437683840622259)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(35387743581829181)
,p_button_name=>'CLEAR_FILTERS'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'&CLEAR_FILTERS.'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:800:&SESSION.::&DEBUG.::P800_RESET:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13449014478622302)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(35497554466984055)
,p_button_name=>'SETUP'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-table-wrench" title="Open in Uploaders"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:805:&SESSION.::&DEBUG.::P805_TABLE_NAME,P805_UPLOADER_ID,P805_RESET:&P800_TARGET.,&P800_TARGET.,Y'
,p_security_scheme=>wwv_flow_api.id(63770652250014528)
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13452516153622315)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(37673622004032103)
,p_button_name=>'COMMIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Commit'
,p_button_position=>'RIGHT_OF_TITLE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13454496038622320)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(25071177918009654)
,p_button_name=>'DOWNLOAD'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-download" title="Download"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:800:&SESSION.::&DEBUG.::P800_DOWNLOAD:&P800_FILE.'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(13454864466622321)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(25071177918009654)
,p_button_name=>'DELETE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-trash-o" title="Delete"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:800:&SESSION.::&DEBUG.::P800_DELETE:&P800_FILE.'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13048640589981119)
,p_name=>'P800_TARGET_NAME'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(46429087864913333)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13438053898622261)
,p_name=>'P800_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35387743581829181)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13438450670622263)
,p_name=>'P800_FILE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(35387743581829181)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13439128216622265)
,p_name=>'P800_SHEET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35497535560984054)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13439827610622267)
,p_name=>'P800_DELETE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(35497432343984053)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13440256902622268)
,p_name=>'P800_DOWNLOAD'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(35497432343984053)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13441361755622271)
,p_name=>'P800_UPLOAD'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(46429087864913333)
,p_prompt=>'Upload'
,p_display_as=>'NATIVE_FILE'
,p_cSize=>30
,p_field_template=>wwv_flow_api.id(63743308864014396)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'APEX_APPLICATION_TEMP_FILES'
,p_attribute_09=>'SESSION'
,p_attribute_10=>'Y'
,p_attribute_12=>'DROPZONE_BLOCK'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13441718631622271)
,p_name=>'P800_UPLOADED'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(46429087864913333)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13442121082622272)
,p_name=>'P800_TARGET'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(46429087864913333)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.component_end;
end;
/
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13442507960622273)
,p_name=>'P800_SESSION'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(46429087864913333)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13443210353622275)
,p_name=>'P800_SHOW_NOT_MAPPED'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35497845337984057)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13449426519622303)
,p_name=>'P800_SHOW_COLS'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35497554466984055)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13450106940622305)
,p_name=>'P800_SHOW_DATA'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35497681472984056)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13450829099622307)
,p_name=>'P800_SHOW_ERRORS'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(35497855932984058)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13452965138622316)
,p_name=>'P800_COMMIT'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(37673622004032103)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13453360649622317)
,p_name=>'P800_PREVIEW'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(37673622004032103)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(13453748017622318)
,p_name=>'P800_SHOW_RESULT'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(37673622004032103)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(13458450759622335)
,p_name=>'CHANGED_UPLOAD'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P800_UPLOAD'
,p_bind_type=>'live'
,p_bind_event_type=>'change'
,p_security_scheme=>wwv_flow_api.id(31236197613688358)
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(13458919093622338)
,p_event_id=>wwv_flow_api.id(13458450759622335)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13457289275622333)
,p_process_sequence=>10
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_SESSION'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- pass session_id to upload/submit',
'apex.set_item(''$SESSION'', sess.get_session_id());',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13456487813622331)
,p_process_sequence=>20
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_SHEET_ON_UPLOAD'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- retrieve first uploaded file',
'FOR c IN (',
'    SELECT file_name, 1 AS sheet_id, uploader_id',
'    FROM (',
'        SELECT f.*',
'        FROM uploaded_files f',
'        WHERE f.created_by = sess.get_user_id()',
'        ORDER BY f.created_at DESC',
'    )',
'    WHERE ROWNUM = 1',
') LOOP',
'    apex.set_item(''$FILE'',      c.file_name);',
'    apex.set_item(''$SHEET'',     c.sheet_id);',
'    apex.set_item(''$TARGET'',    c.uploader_id);',
'END LOOP;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_UPLOADED'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13458099770622334)
,p_process_sequence=>30
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_SHEET_ON_NULL'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- retrieve first sheet and uploader for file',
'IF apex.get_item(''$SHEET'') IS NULL THEN',
'    FOR c IN (',
'        SELECT',
'            f.file_name,',
'            1 AS sheet_id,',
'            f.uploader_id',
'        FROM uploaded_files f',
'        WHERE f.file_name = apex.get_item(''$FILE'')',
'    ) LOOP',
'        apex.set_item(''$FILE'',      c.file_name);',
'        apex.set_item(''$SHEET'',     c.sheet_id);',
'        apex.set_item(''$TARGET'',    c.uploader_id);',
'    END LOOP;',
'END IF;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_FILE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13051384912981146)
,p_process_sequence=>40
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_TARGET_ON_NULL'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- retrieve preferred uploader for sheet',
'FOR c IN (',
'    SELECT f.uploader_id',
'    FROM uploaded_file_sheets f',
'    WHERE f.file_name       = apex.get_item(''$FILE'')',
'        AND f.sheet_id      = apex.get_item(''$SHEET'')',
') LOOP',
'    apex.set_item(''$TARGET'',    c.uploader_id);',
'END LOOP;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_TARGET'
,p_process_when_type=>'ITEM_IS_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13048714910981120)
,p_process_sequence=>50
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_TARGET_NAME'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'FOR c IN (',
'    SELECT CASE WHEN u.region_name IS NOT NULL THEN '' to '' || u.region_name END AS uploader_name',
'    FROM p805_uploaders u',
'    WHERE u.uploader_id = apex.get_item(''$TARGET'')',
') LOOP',
'    apex.set_item(''$TARGET_NAME'', c.uploader_name);',
'END LOOP;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_TARGET'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13455605711622330)
,p_process_sequence=>60
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DELETE_FILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'uploader.delete_file(apex.get_item(''$DELETE''));',
'--',
'apex.set_item(''$DELETE'', NULL);',
'apex.redirect();',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_DELETE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13456041840622331)
,p_process_sequence=>70
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DOWNLOAD_FILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'uploader.download_file(apex.get_item(''$DOWNLOAD''));',
'apex.set_item(''$DOWNLOAD'', NULL);',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_DOWNLOAD'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13455219708622328)
,p_process_sequence=>80
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'PROCESS_SHEET'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'--uploader.process_file (',
'--);',
'NULL;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P800_TARGET'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13457683701622333)
,p_process_sequence=>90
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SHOW_PREVIEW'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- show preview if target is known',
'IF apex.get_item(''$SHEET'') IS NOT NULL AND apex.get_item(''$TARGET'') IS NOT NULL THEN',
'    apex.set_item(''$PREVIEW'', ''Y'');',
'END IF;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13645774829013504)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_region_id=>wwv_flow_api.id(35497554466984055)
,p_process_type=>'NATIVE_IG_DML'
,p_process_name=>'Sheet Columns Mapping'
,p_attribute_01=>'PLSQL_CODE'
,p_attribute_04=>wwv_flow_string.join(wwv_flow_t_varchar2(
'UPDATE uploaders_mapping m',
'SET m.source_column         = :SOURCE_COLUMN,',
'    m.overwrite_value       = :OVERWRITE_VALUE',
'WHERE m.app_id              = sess.get_app_id()',
'    AND m.uploader_id       = apex.get_item(''$TARGET'')',
'    AND m.target_column     = :TARGET_COLUMN;',
''))
,p_attribute_05=>'Y'
,p_attribute_06=>'N'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(13456881299622332)
,p_process_sequence=>10
,p_process_point=>'ON_SUBMIT_BEFORE_COMPUTATION'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'UPLOAD_FILES'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- somehow session_id get lost/changed during submit',
'-- so we pass it via argument',
'tree.log_module(''UPLOADING_FILES'', apex.get_item(''$SESSION''));',
'uploader.upload_files (',
'    in_session_id => apex.get_item(''$SESSION'')',
');',
'--',
'apex.clear_items();',
'apex.redirect(',
'    in_names  => ''P800_UPLOADED'',',
'    in_values => ''Y''',
');',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.component_end;
end;
/
