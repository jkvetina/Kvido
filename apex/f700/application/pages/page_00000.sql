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
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(63772249988014549)
,p_protection_level=>'D'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210313193049'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(13050065109981133)
,p_plug_name=>'Help'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(63687285315014341)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'REGION_POSITION_05'
,p_plug_source=>'<a href="#" style="color: #000;"><span class="fa fa-lg fa-user-md" title=""></span></a>'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(13050107006981134)
,p_plug_name=>'Page Items'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_grid_column_span=>3
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM apex_page_items;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>1000
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_required_role=>wwv_flow_api.id(63770652250014528)
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_02=>'ITEM_NAME'
,p_attribute_06=>'SUPPLEMENTAL_'
,p_attribute_08=>'ITEM_VALUE'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(13050352081981136)
,p_plug_name=>'App Items'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>3
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT * FROM apex_app_items;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_required_role=>wwv_flow_api.id(63770652250014528)
,p_prn_units=>'MILLIMETERS'
,p_prn_paper_size=>'A4'
,p_prn_width=>297
,p_prn_height=>210
,p_prn_orientation=>'HORIZONTAL'
,p_prn_page_header=>'Page Items'
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
,p_attribute_02=>'ITEM_NAME'
,p_attribute_06=>'SUPPLEMENTAL_'
,p_attribute_08=>'ITEM_VALUE'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(89992872435818405)
,p_plug_name=>'USERENV'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>60
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_grid_column_span=>6
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'WITH t AS (',
'    SELECT',
'        ''CLIENT_IDENTIFIER,CLIENT_INFO,ACTION,MODULE,'' ||',
'        ''CURRENT_SCHEMA,CURRENT_USER,CURRENT_EDITION_ID,CURRENT_EDITION_NAME,'' ||',
'        ''OS_USER,POLICY_INVOKER,'' ||',
'        ''SESSION_USER,SESSIONID,SID,SESSION_EDITION_ID,SESSION_EDITION_NAME,'' ||',
'        ''AUTHENTICATED_IDENTITY,AUTHENTICATION_DATA,AUTHENTICATION_METHOD,IDENTIFICATION_TYPE,'' ||',
'        ''ENTERPRISE_IDENTITY,PROXY_ENTERPRISE_IDENTITY,PROXY_USER,'' ||',
'        ''GLOBAL_CONTEXT_MEMORY,GLOBAL_UID,'' ||',
'        ''AUDITED_CURSORID,ENTRYID,STATEMENTID,CURRENT_SQL,CURRENT_BIND,'' ||',
'        ''HOST,SERVER_HOST,SERVICE_NAME,IP_ADDRESS,'' ||',
'        ''DB_DOMAIN,DB_NAME,DB_UNIQUE_NAME,DBLINK_INFO,DATABASE_ROLE,ISDBA,'' ||',
'        ''INSTANCE,INSTANCE_NAME,NETWORK_PROTOCOL,'' ||',
'        ''LANG,LANGUAGE,NLS_TERRITORY,NLS_CURRENCY,NLS_SORT,NLS_DATE_FORMAT,NLS_DATE_LANGUAGE,NLS_CALENDAR,'' ||',
'        ''BG_JOB_ID,FG_JOB_ID'' AS str',
'    FROM DUAL',
')',
'SELECT',
'    t.name,',
'    t.value',
'FROM (',
'    SELECT',
'        REGEXP_SUBSTR(str, ''[^,]+'', 1, LEVEL) AS name,',
'        SYS_CONTEXT(''USERENV'', REGEXP_SUBSTR(str, ''[^,]+'', 1, LEVEL)) AS value',
'    FROM t',
'    CONNECT BY LEVEL <= REGEXP_COUNT(str, '','')',
') t',
'WHERE t.value IS NOT NULL',
'ORDER BY 1;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_required_role=>wwv_flow_api.id(63770652250014528)
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>'apex.is_debug()'
,p_plug_display_when_cond2=>'PLSQL'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'SEARCH'
,p_attribute_02=>'NAME'
,p_attribute_08=>'VALUE'
,p_attribute_18=>'CLIENT'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(89992987819818406)
,p_plug_name=>'CGI'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>70
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>6
,p_plug_display_point=>'REGION_POSITION_05'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'WITH t AS (',
'    SELECT',
'        ''QUERY_STRING,AUTHORIZATION,DAD_NAME,DOC_ACCESS_PATH,DOCUMENT_TABLE,'' ||',
'        ''HTTP_ACCEPT,HTTP_ACCEPT_ENCODING,HTTP_ACCEPT_CHARSET,HTTP_ACCEPT_LANGUAGE,'' ||',
'        ''HTTP_COOKIE,HTTP_HOST,HTTP_PRAGMA,HTTP_REFERER,HTTP_USER_AGENT,'' ||',
'        ''PATH_ALIAS,PATH_INFO,REMOTE_ADDR,REMOTE_HOST,REMOTE_USER,'' ||',
'        ''REQUEST_CHARSET,REQUEST_IANA_CHARSET,REQUEST_METHOD,REQUEST_PROTOCOL,'' ||',
'        ''SCRIPT_NAME,SCRIPT_PREFIX,SERVER_NAME,SERVER_PORT,SERVER_PROTOCOL'' AS str',
'    FROM DUAL',
')',
'SELECT',
'    REGEXP_SUBSTR(str, ''[^,]+'', 1, LEVEL) AS name,',
'    REGEXP_REPLACE(OWA_UTIL.GET_CGI_ENV(REGEXP_SUBSTR(str, ''[^,]+'', 1, LEVEL)), ''([;)])'', ''\1',
''') AS value',
'FROM t',
'CONNECT BY LEVEL <= REGEXP_COUNT(str, '','')',
'ORDER BY 1;',
''))
,p_plug_source_type=>'NATIVE_JQM_LIST_VIEW'
,p_plug_query_num_rows=>15
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_required_role=>wwv_flow_api.id(63770652250014528)
,p_plug_display_condition_type=>'EXPRESSION'
,p_plug_display_when_condition=>'apex.is_debug()'
,p_plug_display_when_cond2=>'PLSQL'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<br />',
''))
,p_attribute_01=>'ADVANCED_FORMATTING:SEARCH'
,p_attribute_05=>'&NAME.'
,p_attribute_08=>'VALUE'
,p_attribute_18=>'CLIENT'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(13050561578981138)
,p_name=>'ON_PAGE_LOAD'
,p_event_sequence=>10
,p_bind_type=>'bind'
,p_bind_event_type=>'ready'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(13050641057981139)
,p_event_id=>wwv_flow_api.id(13050561578981138)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'apex_page_loaded();',
''))
);
wwv_flow_api.component_end;
end;
/
