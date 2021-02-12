prompt --application/pages/page_00851
begin
--   Manifest
--     PAGE: 00851
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
 p_id=>851
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'#fa-files-o Uploaded Files'
,p_alias=>'RECENT-FILES'
,p_step_title=>'Uploaded Files'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(10819719419852508)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210211233212'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10830793568034150)
,p_plug_name=>'Uploaded Files'
,p_region_template_options=>'#DEFAULT#'
,p_escape_on_http_output=>'Y'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'--',
'-- CREATE AS VIEW',
'--',
'SELECT',
'    u.file_name,',
'    ---------------- add short name for user',
'    u.file_size,',
'    u.mime_type,',
'    u.uploader_id,',
'    u.updated_by,',
'    u.updated_at',
'FROM uploaded_files u',
'WHERE (u.app_id, u.session_id, u.updated_at) IN (',
'    SELECT u.app_id, u.session_id, MAX(u.updated_at) AS updated_at',
'    FROM uploaded_files u',
'    WHERE u.app_id          = sess.get_app_id()',
'        AND u.session_id    = sess.get_session_id()',
'    GROUP BY u.app_id, u.session_id',
');',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'FILE_NAME'
,p_attribute_16=>'f?p=&APP_ID.:851:&SESSION.::&DEBUG.::P851_FILE:&FILE_NAME.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10939582894189013)
,p_plug_name=>'File Info'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SIZE, TYPE<br />',
'DELETE<br />',
'DOWNLOAD<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940482330189022)
,p_plug_name=>'File Sheets #fa-emoji-cry for .CSV'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>40
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'LIST OF SHEETS (LIST VIEW)<br />',
'SHOW CURRENT SHEET BOLD<br />',
'SHOW CURRENT FILE BOLD<br />',
'ICONS ??<br />',
'AUTOMATICALLY SELECT 1 FILE, 1 SHEET<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940585547189023)
,p_plug_name=>'Sheet Content'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>50
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'COLS (#) - [SHOW MAPPINGS]<br />',
'ROWS (#) - [SHOW DATA] WITH CORRECT COL_NAMES<br />',
'SHOW TARGET % MATCH<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940604453189024)
,p_plug_name=>'Sheet Columns Mapping'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>90
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940731459189025)
,p_plug_name=>'Sheet Data'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>100
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940895324189026)
,p_plug_name=>'Not Mapped Rows'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>110
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10940905919189027)
,p_plug_name=>'Invalid Rows'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>120
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10941067903189028)
,p_plug_name=>'Preview'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>70
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'AFTER PREPARE<br />',
'SHOW RESULTS + CHART<br />',
'SHOW ERRORS FROM ERR TABLE<br />',
'SHOW NOT MAPPED ROWS<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10941162965189029)
,p_plug_name=>'Result'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>80
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'AFTER COMMIT<br />',
'SHOW RESULTS + CHART<br />',
'SHOW ERRORS FROM ERR TABLE<br />',
'SHOW NOT MAPPED ROWS<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10941404533189032)
,p_plug_name=>'Recent Files (not above)'
,p_region_template_options=>'#DEFAULT#'
,p_escape_on_http_output=>'Y'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'--',
'-- CREATE AS VIEW',
'--',
'SELECT',
'    u.file_name,',
'    ---------------- add short name for user',
'    u.file_size,',
'    u.mime_type,',
'    u.uploader_id,',
'    u.updated_by,',
'    u.updated_at',
'FROM uploaded_files u',
'WHERE u.app_id        = sess.get_app_id()',
'    AND u.updated_by  = sess.get_user_id()',
'ORDER BY u.updated_at DESC;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_prn_units=>'MILLIMETERS'
,p_prn_paper_size=>'A4'
,p_prn_width=>297
,p_prn_height=>210
,p_prn_orientation=>'HORIZONTAL'
,p_prn_page_header=>'Uploaded Files'
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
'<br />',
''))
,p_attribute_02=>'FILE_NAME'
,p_attribute_16=>'f?p=&APP_ID.:851:&SESSION.::&DEBUG.::P851_FILE:&FILE_NAME.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(10942457533189042)
,p_plug_name=>'Alternatove Target*'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>60
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SHOW POSSIBLE TARGETS<br />',
'ONLY WHEN BUTTON^ PRESSED<br />',
'PREVIEW BUTTON NOT HOT<br />',
'RESULTS HIDDEN<br />',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10942218651189040)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10941067903189028)
,p_button_name=>'COMMIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Commit'
,p_button_position=>'BELOW_BOX'
,p_button_alignment=>'LEFT'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10942644789189044)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10942457533189042)
,p_button_name=>'CHANGE_ACTION'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Change'
,p_button_position=>'BELOW_BOX'
,p_button_alignment=>'LEFT'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10942148508189039)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(10940585547189023)
,p_button_name=>'PREVIEW'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Preview'
,p_button_position=>'BELOW_BOX'
,p_button_alignment=>'LEFT'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10941222264189030)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10830793568034150)
,p_button_name=>'CLEAR_FILTERS'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'&CLEAR_FILTERS.'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:851:&SESSION.::&DEBUG.::P851_RESET:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10941861731189036)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10939582894189013)
,p_button_name=>'DOWNLOAD'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Download'
,p_button_position=>'RIGHT_OF_TITLE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10942052537189038)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10940585547189023)
,p_button_name=>'CHANGE_TARGET'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Change Target'
,p_button_position=>'RIGHT_OF_TITLE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10942368713189041)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(10941404533189032)
,p_button_name=>'LOAD_MORE'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Load More'
,p_button_position=>'RIGHT_OF_TITLE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(10941919401189037)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(10939582894189013)
,p_button_name=>'DELETE'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Delete'
,p_button_position=>'RIGHT_OF_TITLE'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(10939497005189012)
,p_name=>'P851_FILE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(10830793568034150)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(10939615730189014)
,p_name=>'P851_FILE_1'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(10939582894189013)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(10941357068189031)
,p_name=>'P851_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(10830793568034150)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(10941523951189033)
,p_name=>'P851_FILE_2'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(10941404533189032)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(10941607788189034)
,p_name=>'P851_RESET_1'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(10941404533189032)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.component_end;
end;
/
