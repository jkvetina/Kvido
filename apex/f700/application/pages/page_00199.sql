prompt --application/pages/page_00199
begin
--   Manifest
--     PAGE: 00199
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
 p_id=>199
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'${USER_NAME}'
,p_alias=>'USER'
,p_step_title=>'User Info'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(9619968066909198)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_css_classes=>'USER_NAME'
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210425111909'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(51084378175768182)
,p_plug_name=>'User Info (&P199_USER_ID.)'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_grid_column_span=>4
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM p199_user_info;',
''))
,p_is_editable=>true
,p_edit_operations=>'u'
,p_lost_update_check_type=>'VALUES'
,p_plug_source_type=>'NATIVE_FORM'
,p_ajax_items_to_submit=>'P199_USER_ID'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(51241095578880907)
,p_plug_name=>'Application Roles'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>4
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT r.role_id',
'FROM user_roles r',
'WHERE r.app_id      = sess.get_app_id()',
'    AND r.is_active = ''Y''',
'UNION ALL',
'SELECT ''IS_DEVELOPER''',
'FROM DUAL',
'WHERE apex.is_developer_y_null() = ''Y''',
'ORDER BY 1;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_02=>'ROLE_ID'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(51085852844768197)
,p_button_sequence=>100
,p_button_plug_id=>wwv_flow_api.id(51084378175768182)
,p_button_name=>'SUBMIT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Submit'
,p_button_position=>'BODY'
,p_button_cattributes=>'style="margin-top: 1.6rem;"'
,p_grid_new_row=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(9539405078654001)
,p_name=>'P199_USER_LOGIN'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_prompt=>'User Login'
,p_source=>'USER_LOGIN'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>128
,p_field_template=>wwv_flow_api.id(63743308864014396)
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(9539540607654002)
,p_name=>'P199_USER_NAME'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_prompt=>'User Name'
,p_source=>'USER_NAME'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>64
,p_field_template=>wwv_flow_api.id(63743308864014396)
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(9539791311654004)
,p_name=>'P199_UPDATED_BY'
,p_source_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_source=>'UPDATED_BY'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(9539823515654005)
,p_name=>'P199_UPDATED_AT'
,p_source_data_type=>'DATE'
,p_is_query_only=>true
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_source=>'UPDATED_AT'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(11630917346387403)
,p_name=>'P199_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(12477622595064815)
,p_name=>'P199_IS_ACTIVE'
,p_source_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_source=>'IS_ACTIVE'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(42894764515353724)
,p_name=>'P199_IS_DEV'
,p_source_data_type=>'VARCHAR2'
,p_is_query_only=>true
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_source=>'IS_DEV'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(51084501674768184)
,p_name=>'P199_USER_ID'
,p_source_data_type=>'VARCHAR2'
,p_is_primary_key=>true
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_source=>'USER_ID'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(89995962431818436)
,p_name=>'P199_LANG_ID'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(51084378175768182)
,p_item_source_plug_id=>wwv_flow_api.id(51084378175768182)
,p_prompt=>'Lang Id'
,p_source=>'LANG_ID'
,p_source_type=>'REGION_SOURCE_COLUMN'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>5
,p_field_template=>wwv_flow_api.id(63743308864014396)
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(51085774627768196)
,p_process_sequence=>10
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'PREFILL_FORM'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'apex.log_after_header(''PREFILL_FORM'');',
'--',
'APEX_UTIL.SET_SESSION_STATE(''P199_USER_ID'', sess.get_user_id());',
'--',
'FOR c IN (',
'    SELECT u.*',
'    FROM users u',
'    WHERE u.user_id = sess.get_user_id()',
') LOOP',
'    APEX_UTIL.SET_SESSION_STATE(''P199_USER_LOGIN'', c.user_login);',
'    APEX_UTIL.SET_SESSION_STATE(''P199_USER_NAME'',  c.user_name);',
'    APEX_UTIL.SET_SESSION_STATE(''P199_LANG_ID'',    c.lang_id);',
'END LOOP;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(51085510312768194)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SUBMIT'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- should be in procedure with error handler',
'UPDATE users u',
'SET u.user_login = :P199_USER_LOGIN,',
'    u.user_name  = :P199_USER_NAME,',
'    u.lang_id    = :P199_LANG_ID',
'WHERE u.user_id  = sess.get_user_id();',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_success_message=>'SUCCESS'
);
wwv_flow_api.component_end;
end;
/
