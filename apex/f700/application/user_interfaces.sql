prompt --application/user_interfaces
begin
--   Manifest
--     USER INTERFACES: 700
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_user_interface(
 p_id=>wwv_flow_api.id(63766922917014449)
,p_ui_type_name=>'DESKTOP'
,p_display_name=>'Desktop'
,p_display_seq=>10
,p_use_auto_detect=>false
,p_is_default=>true
,p_theme_id=>42
,p_home_url=>'f?p=&APP_ID.:home:&SESSION.'
,p_login_url=>'f?p=&APP_ID.:9999:&SESSION.'
,p_theme_style_by_user_pref=>false
,p_built_with_love=>false
,p_navigation_list_id=>wwv_flow_api.id(77155376142062545)
,p_navigation_list_position=>'TOP'
,p_navigation_list_template_id=>wwv_flow_api.id(64163400516768059)
,p_nav_list_template_options=>'#DEFAULT#'
,p_css_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#APP_IMAGES#fonts.css?version=#APP_VERSION#',
'#APP_IMAGES#app.css?version=#APP_VERSION#'))
,p_javascript_file_urls=>'#APP_IMAGES#app.js?version=#APP_VERSION#'
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_api.id(63766650152014448)
,p_nav_bar_list_template_id=>wwv_flow_api.id(64163400516768059)
,p_nav_bar_template_options=>'#DEFAULT#'
);
wwv_flow_api.component_end;
end;
/
