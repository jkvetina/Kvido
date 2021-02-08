prompt --application/shared_components/user_interface/themes
begin
--   Manifest
--     THEME: 700
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_theme(
 p_id=>wwv_flow_api.id(63747286284014426)
,p_theme_id=>42
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_ui_type_name=>'DESKTOP'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_reference_id=>4070917134413059350
,p_is_locked=>false
,p_default_page_template=>wwv_flow_api.id(64127379571157916)
,p_default_dialog_template=>wwv_flow_api.id(63641917228014285)
,p_error_template=>wwv_flow_api.id(63643432606014288)
,p_printer_friendly_template=>wwv_flow_api.id(63656907698014303)
,p_breadcrumb_display_point=>'REGION_POSITION_01'
,p_sidebar_display_point=>'REGION_POSITION_02'
,p_login_template=>wwv_flow_api.id(63643432606014288)
,p_default_button_template=>wwv_flow_api.id(63744470351014400)
,p_default_region_template=>wwv_flow_api.id(64142195941700285)
,p_default_chart_template=>wwv_flow_api.id(64142195941700285)
,p_default_form_template=>wwv_flow_api.id(64142195941700285)
,p_default_reportr_template=>wwv_flow_api.id(64142195941700285)
,p_default_tabform_template=>wwv_flow_api.id(63688378416014341)
,p_default_wizard_template=>wwv_flow_api.id(64142195941700285)
,p_default_menur_template=>wwv_flow_api.id(63697793061014351)
,p_default_listr_template=>wwv_flow_api.id(64142195941700285)
,p_default_irr_template=>wwv_flow_api.id(64142195941700285)
,p_default_report_template=>wwv_flow_api.id(63708617940014365)
,p_default_label_template=>wwv_flow_api.id(63743308864014396)
,p_default_menu_template=>wwv_flow_api.id(63745877961014402)
,p_default_calendar_template=>wwv_flow_api.id(63745923092014406)
,p_default_list_template=>wwv_flow_api.id(63741406632014391)
,p_default_nav_list_template=>wwv_flow_api.id(63732886280014386)
,p_default_top_nav_list_temp=>wwv_flow_api.id(63732886280014386)
,p_default_side_nav_list_temp=>wwv_flow_api.id(63731797368014386)
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>wwv_flow_api.id(63673677715014329)
,p_default_dialogr_template=>wwv_flow_api.id(63663131534014321)
,p_default_option_label=>wwv_flow_api.id(63743308864014396)
,p_default_required_label=>wwv_flow_api.id(63743645750014397)
,p_default_page_transition=>'NONE'
,p_default_popup_transition=>'NONE'
,p_default_navbar_list_template=>wwv_flow_api.id(63733796138014387)
,p_file_prefix => nvl(wwv_flow_application_install.get_static_theme_file_prefix(42),'#IMAGE_PREFIX#themes/theme_42/1.3/')
,p_files_version=>62
,p_icon_library=>'FONTAPEX'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#IMAGE_PREFIX#libraries/apex/#MIN_DIRECTORY#widget.stickyWidget#MIN#.js?v=#APEX_VERSION#',
'#THEME_IMAGES#js/theme42#MIN#.js?v=#APEX_VERSION#'))
,p_css_file_urls=>'#THEME_IMAGES#css/Core#MIN#.css?v=#APEX_VERSION#'
);
wwv_flow_api.component_end;
end;
/
