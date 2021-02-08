prompt --application/pages/page_00900
begin
--   Manifest
--     PAGE: 00900
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
 p_id=>900
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'#fa-server-wrench'
,p_alias=>'DASHBOARD'
,p_step_title=>'Dashboard'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(64766608684607384)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_api.id(63770652250014528)
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210208192228'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(67910472130821334)
,p_plug_name=>'Invalid Objects'
,p_region_template_options=>'#DEFAULT#'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT o.object_type, o.object_name, o.subobject_name, o.status, o.last_ddl_time',
'FROM user_objects o',
'WHERE o.status != ''VALID''',
'ORDER BY 1, 2, 3;'))
,p_plug_source_type=>'NATIVE_IR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_prn_content_disposition=>'ATTACHMENT'
,p_prn_document_header=>'APEX'
,p_prn_units=>'INCHES'
,p_prn_paper_size=>'LETTER'
,p_prn_width=>8.5
,p_prn_height=>11
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
 p_id=>wwv_flow_api.id(67910634236821335)
,p_max_row_count=>'1000000'
,p_show_nulls_as=>'-'
,p_pagination_type=>'ROWS_X_TO_Y_OF_Z'
,p_pagination_display_pos=>'BOTTOM_RIGHT'
,p_report_list_mode=>'TABS'
,p_show_detail_link=>'N'
,p_show_notify=>'Y'
,p_download_formats=>'CSV:HTML:XLSX:PDF:RTF:EMAIL'
,p_owner=>'JKVETINA'
,p_internal_uid=>67910634236821335
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31319993978875778)
,p_db_column_name=>'OBJECT_TYPE'
,p_display_order=>10
,p_column_identifier=>'A'
,p_column_label=>'Object Type'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31320371043875778)
,p_db_column_name=>'OBJECT_NAME'
,p_display_order=>20
,p_column_identifier=>'B'
,p_column_label=>'Object Name'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31320711901875779)
,p_db_column_name=>'SUBOBJECT_NAME'
,p_display_order=>30
,p_column_identifier=>'C'
,p_column_label=>'Subobject Name'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31321185937875780)
,p_db_column_name=>'STATUS'
,p_display_order=>40
,p_column_identifier=>'D'
,p_column_label=>'Status'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(31321501919875781)
,p_db_column_name=>'LAST_DDL_TIME'
,p_display_order=>50
,p_column_identifier=>'E'
,p_column_label=>'Last Ddl Time'
,p_column_type=>'DATE'
,p_column_alignment=>'CENTER'
,p_tz_dependent=>'N'
);
wwv_flow_api.create_worksheet_rpt(
 p_id=>wwv_flow_api.id(67980180034317931)
,p_application_user=>'APXWS_DEFAULT'
,p_report_seq=>10
,p_report_alias=>'313219'
,p_status=>'PUBLIC'
,p_is_default=>'Y'
,p_report_columns=>'OBJECT_TYPE:OBJECT_NAME:SUBOBJECT_NAME:STATUS:LAST_DDL_TIME'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(71819787564897425)
,p_plug_name=>'Dashboard'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM p900_dashboard;',
''))
,p_plug_source_type=>'NATIVE_IG'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54372616585354812)
,p_name=>'TODAY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TODAY'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Today'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>10
,p_value_alignment=>'CENTER'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_TODAY,P901_RESET:&TODAY.,Y'
,p_link_text=>'&TODAY.'
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
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54372719941354813)
,p_name=>'MODULES'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'MODULES'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Modules'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>20
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:M,&TODAY.,Y'
,p_link_text=>'&MODULES.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54372780848354814)
,p_name=>'ACTIONS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'ACTIONS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Actions'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>30
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:A,&TODAY.,Y'
,p_link_text=>'&ACTIONS.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54372935842354815)
,p_name=>'DEBUGS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DEBUGS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Debugs'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>40
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:D,&TODAY.,Y'
,p_link_text=>'&DEBUGS.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373039756354816)
,p_name=>'INFO'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'INFO'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Info'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>50
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:I,&TODAY.,Y'
,p_link_text=>'&INFO.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373105355354817)
,p_name=>'RESULTS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'RESULTS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Results'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>60
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:R,&TODAY.,Y'
,p_link_text=>'&RESULTS.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373166694354818)
,p_name=>'WARNINGS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'WARNINGS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Warnings'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>70
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:W,&TODAY.,Y'
,p_link_text=>'&WARNINGS.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373307983354819)
,p_name=>'ERRORS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'ERRORS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Errors'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>80
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_FLAG,P901_TODAY,P901_RESET:E,&TODAY.,Y'
,p_link_text=>'&ERRORS.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373379094354820)
,p_name=>'LONGOPS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LONGOPS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'Longops'
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
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373473054354821)
,p_name=>'SCHEDULERS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'SCHEDULERS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'Schedulers'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>100
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
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54373744849354823)
,p_name=>'LOBS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LOBS'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'Lobs'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>120
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
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54484323348385574)
,p_name=>'TOTAL'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TOTAL'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Total'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>130
,p_value_alignment=>'RIGHT'
,p_link_target=>'f?p=&APP_ID.:901:&SESSION.::&DEBUG.:RP:P901_TODAY,P901_RESET:&TODAY.,Y'
,p_link_text=>'&TOTAL.'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(54484395124385575)
,p_name=>'ACTION'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'ACTION'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_type=>'NATIVE_LINK'
,p_heading=>'Action'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>140
,p_value_alignment=>'CENTER'
,p_link_target=>'f?p=&APP_ID.:900:&SESSION.::&DEBUG.:RP:P900_DELETE,P900_DELETE_OLD:&TODAY.,'
,p_link_text=>'&ACTION.'
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
,p_escape_on_http_output=>true
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(54372546010354811)
,p_internal_uid=>54372546010354811
,p_is_editable=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_show_nulls_as=>'-'
,p_select_first_row=>false
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>true
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SAVE'
,p_enable_save_public_report=>false
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>true
,p_enable_mail_download=>true
,p_fixed_header=>'PAGE'
,p_show_icon_view=>false
,p_show_detail_view=>false
);
wwv_flow_api.create_ig_report(
 p_id=>wwv_flow_api.id(54490058517386856)
,p_interactive_grid_id=>wwv_flow_api.id(54372546010354811)
,p_static_id=>'312290'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(54490206071386857)
,p_report_id=>wwv_flow_api.id(54490058517386856)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54490689812386861)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(54372616585354812)
,p_is_visible=>true
,p_is_frozen=>false
,p_sort_order=>1
,p_sort_direction=>'DESC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54491165561386865)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(54372719941354813)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54491660744386867)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(54372780848354814)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54492229096386868)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(54372935842354815)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54492676603386870)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(54373039756354816)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54493157570386871)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(54373105355354817)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54493669609386872)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(54373166694354818)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54494183634386874)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>8
,p_column_id=>wwv_flow_api.id(54373307983354819)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54494712082386875)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>9
,p_column_id=>wwv_flow_api.id(54373379094354820)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54495188584386876)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>10
,p_column_id=>wwv_flow_api.id(54373473054354821)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54496231235386879)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>12
,p_column_id=>wwv_flow_api.id(54373744849354823)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54496736846386880)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>13
,p_column_id=>wwv_flow_api.id(54484323348385574)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(54497169217386881)
,p_view_id=>wwv_flow_api.id(54490206071386857)
,p_display_seq=>14
,p_column_id=>wwv_flow_api.id(54484395124385575)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(31322374264875783)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(67910472130821334)
,p_button_name=>'RECOMPILE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Recompile'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:900:&SESSION.::&DEBUG.:RP:P900_RECOMPILE:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(31330584376875804)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(71819787564897425)
,p_button_name=>'DELETE_OLD'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Delete (7 days old)'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:900:&SESSION.::&DEBUG.:RP:P900_DELETE_OLD:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(31322710052875785)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(67910472130821334)
,p_button_name=>'RECOMPILE_FORCE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Force All'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:900:&SESSION.::&DEBUG.:RP:P900_FORCE:Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31323183182875786)
,p_name=>'P900_RECOMPILE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(67910472130821334)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31323528691875787)
,p_name=>'P900_FORCE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(67910472130821334)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31330995658875805)
,p_name=>'P900_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(71819787564897425)
,p_source=>'Y'
,p_source_type=>'STATIC'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31331389291875806)
,p_name=>'P900_DELETE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(71819787564897425)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31331737351875807)
,p_name=>'P900_DELETE_OLD'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(71819787564897425)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(31332148780875808)
,p_process_sequence=>10
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DELETE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DELETE FROM logs e',
'WHERE e.created_at    >= TO_DATE(:P900_DELETE, ''YYYY-MM-DD'')',
'    AND e.created_at  <  TO_DATE(:P900_DELETE, ''YYYY-MM-DD'') + 1;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P900_DELETE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(31333380832875811)
,p_process_sequence=>20
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DELETE_OLD'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'tree.purge_old(7);',
'--',
'EXECUTE IMMEDIATE ''ALTER TABLE logs ENABLE ROW MOVEMENT'';',
'EXECUTE IMMEDIATE ''ALTER TABLE logs SHRINK SPACE'';',
'EXECUTE IMMEDIATE ''ALTER TABLE logs DISABLE ROW MOVEMENT'';',
'--',
'DBMS_STATS.GATHER_TABLE_STATS(''CHR'', ''LOGS'');',
'EXECUTE IMMEDIATE ''ANALYZE TABLE CHR.logs COMPUTE STATISTICS FOR TABLE'';',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P900_DELETE_OLD'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(31332519753875809)
,p_process_sequence=>30
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'RECOMPILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'recompile();',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P900_RECOMPILE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(31332984441875810)
,p_process_sequence=>40
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'RECOMPILE_FORCE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'EXECUTE IMMEDIATE',
'    ''ALTER SESSION SET PLSQL_CODE_TYPE = '' || ''INTERPRETED'';',
'EXECUTE IMMEDIATE',
'    ''ALTER SESSION SET PLSCOPE_SETTINGS = '''''' || ''IDENTIFIERS:ALL, STATEMENTS:ALL'' || '''''''';',
'--',
'DBMS_UTILITY.COMPILE_SCHEMA (',
'    schema      => USER,',
'    compile_all => TRUE',
');',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P900_FORCE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.component_end;
end;
/
