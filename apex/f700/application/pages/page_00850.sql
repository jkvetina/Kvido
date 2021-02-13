prompt --application/pages/page_00850
begin
--   Manifest
--     PAGE: 00850
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
 p_id=>850
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'#fa-file-excel-o'
,p_alias=>'UPLOADER'
,p_step_title=>'Uploader'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(10819719419852508)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210213185510'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(21951343639206968)
,p_plug_name=>'Uploaded Files'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_plug_grid_column_span=>3
,p_plug_grid_column_css_classes=>'NO_ARROWS'
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM p850_uploaded_files;',
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
 p_id=>wwv_flow_api.id(22061032401361840)
,p_plug_name=>'File Sheets'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>40
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT s.*',
'FROM p850_uploaded_file_sheets s',
'ORDER BY s.sheet_id;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_FILE'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061135618361841)
,p_plug_name=>'Sheet Content'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>50
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT s.*',
'FROM p850_uploaded_sheet_content s;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHEET'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_08=>'COUNT_'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061154524361842)
,p_plug_name=>'Sheet Columns Mapping'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>110
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHOW_COLS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061281530361843)
,p_plug_name=>'Sheet Data'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>120
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHOW_DATA'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061445395361844)
,p_plug_name=>'Not Mapped Rows'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>130
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHOW_NOT_MAPPED'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061455990361845)
,p_plug_name=>'Rows with Errors'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>140
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHOW_ERRORS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061617974361846)
,p_plug_name=>'Preview'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>70
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
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_PREVIEW'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061713036361847)
,p_plug_name=>'Result'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>80
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
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_COMMIT'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22061954604361850)
,p_plug_name=>'Recent Files'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT f.*',
'FROM p850_recent_files f',
'ORDER BY f.updated_at DESC;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'EXISTS'
,p_plug_display_when_condition=>'SELECT 1 FROM p850_recent_files;'
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
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(22063007604361860)
,p_plug_name=>'Target'
,p_region_css_classes=>'NO_ARROWS'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>60
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT t.*',
'FROM p850_uploaded_targets t;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NOT_NULL'
,p_plug_display_when_condition=>'P850_SHEET'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'LIST_LABEL'
,p_attribute_06=>'SUPPLEMENTAL'
,p_attribute_16=>'&TARGET_URL.'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(32992687922291120)
,p_plug_name=>'Upload File'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'ITEM_IS_NULL'
,p_plug_display_when_condition=>'P850_FILE'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(11128163384172869)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(22061617974361846)
,p_button_name=>'COMMIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Commit'
,p_button_position=>'BELOW_BOX'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(11125824541172863)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(32992687922291120)
,p_button_name=>'SUBMIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Submit'
,p_button_position=>'BELOW_BOX'
,p_button_execute_validations=>'N'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(11121485996172850)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(21951343639206968)
,p_button_name=>'CLEAR_FILTERS'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'&CLEAR_FILTERS.'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:850:&SESSION.::&DEBUG.::P850_RESET:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(11123958994172859)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(22061032401361840)
,p_button_name=>'DOWNLOAD'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-download" title="Download"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:850:&SESSION.::&DEBUG.::P850_DOWNLOAD:&P850_FILE.'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(11124393620172860)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(22061032401361840)
,p_button_name=>'DELETE'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'<span class="fa fa-trash-o" title="Delete"></span>'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:850:&SESSION.::&DEBUG.::P850_DELETE:&P850_FILE.'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11121838929172852)
,p_name=>'P850_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(21951343639206968)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11122210530172854)
,p_name=>'P850_FILE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(21951343639206968)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11122994086172856)
,p_name=>'P850_SHEET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061135618361841)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11124724933172861)
,p_name=>'P850_DELETE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(22061032401361840)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11125103027172861)
,p_name=>'P850_DOWNLOAD'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(22061032401361840)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11126200720172865)
,p_name=>'P850_UPLOAD'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(32992687922291120)
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
 p_id=>wwv_flow_api.id(11126696975172866)
,p_name=>'P850_UPLOADED'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(32992687922291120)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11127075809172867)
,p_name=>'P850_TARGET'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(32992687922291120)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11127452465172868)
,p_name=>'P850_SESSION'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(32992687922291120)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11128577799172870)
,p_name=>'P850_PREVIEW'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061617974361846)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11129276263172872)
,p_name=>'P850_COMMIT'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061713036361847)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11129908013172874)
,p_name=>'P850_SHOW_NOT_MAPPED'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061445395361844)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11130633381172875)
,p_name=>'P850_SHOW_COLS'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061154524361842)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11131331307172877)
,p_name=>'P850_SHOW_DATA'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061281530361843)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11132028331172879)
,p_name=>'P850_SHOW_ERRORS'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(22061455990361845)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(11134051151172889)
,p_name=>'CHANGED_UPLOAD'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P850_UPLOAD'
,p_bind_type=>'live'
,p_bind_event_type=>'change'
,p_security_scheme=>wwv_flow_api.id(31236197613688358)
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(11134543829172891)
,p_event_id=>wwv_flow_api.id(11134051151172889)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(11209892581964043)
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
 p_id=>wwv_flow_api.id(11133270371172887)
,p_process_sequence=>20
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SET_SHEET_AFTER_UPLOAD'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- retrieve first uploaded file',
'IF apex.get_item(''$UPLOADED'') = ''Y'' THEN',
'    FOR c IN (',
'        SELECT file_name',
'        FROM (',
'            SELECT f.file_name',
'            FROM uploaded_files f',
'            WHERE f.session_id = sess.get_session_id()',
'            ORDER BY updated_at DESC',
'        )',
'        WHERE ROWNUM = 1',
'    ) LOOP',
'        apex.set_item(''$FILE'', c.file_name);',
'        apex.set_item(''$SHEET'', 1);',
'    END LOOP;',
'END IF;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(11132423551172885)
,p_process_sequence=>30
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
,p_process_when=>'P850_DELETE'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(11132858305172886)
,p_process_sequence=>40
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DOWNLOAD_FILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'uploader.download_file(apex.get_item(''$DOWNLOAD''));',
'apex.set_item(''$DOWNLOAD'', NULL);',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P850_DOWNLOAD'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(11028738049764218)
,p_process_sequence=>50
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
,p_process_when=>'P850_TARGET'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(11209942202964044)
,p_process_sequence=>60
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
 p_id=>wwv_flow_api.id(11133616379172887)
,p_process_sequence=>10
,p_process_point=>'ON_SUBMIT_BEFORE_COMPUTATION'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'UPLOAD_FILES'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- somehow session_id get lost/changed during submit',
'-- so we pass it via argument',
'uploader.upload_files (',
'    in_session_id => apex.get_item(''$SESSION'')',
');',
'--',
'apex.clear_items();',
'apex.redirect(',
'    in_names  => ''P850_UPLOADED'',',
'    in_values => ''Y''',
');',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.component_end;
end;
/
