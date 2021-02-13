prompt --application/create_application
begin
--   Manifest
--     FLOW: 700
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_flow(
 p_id=>wwv_flow.g_flow_id
,p_owner=>nvl(wwv_flow_application_install.get_schema,'DEV')
,p_name=>nvl(wwv_flow_application_install.get_application_name,'KVIDO')
,p_alias=>nvl(wwv_flow_application_install.get_application_alias,'700')
,p_page_view_logging=>'NO'
,p_page_protection_enabled_y_n=>'Y'
,p_checksum_salt=>'0A061D9815F6A4CD19F2D2F31B1403FA5B0C79C09B162D9479F3C5B7BA84EB5E'
,p_bookmark_checksum_function=>'MD5'
,p_accept_old_checksums=>false
,p_max_session_length_sec=>0
,p_max_session_idle_sec=>0
,p_compatibility_mode=>'19.2'
,p_flow_language=>'en-gb'
,p_flow_language_derived_from=>'FLOW_PRIMARY_LANGUAGE'
,p_date_format=>'YYYY-MM-DD HH24:MI'
,p_date_time_format=>'YYYY-MM-DD HH24:MI'
,p_timestamp_format=>'YYYY-MM-DD HH24:MI:SS'
,p_timestamp_tz_format=>'YYYY-MM-DD HH24:MI:SS'
,p_direction_right_to_left=>'N'
,p_flow_image_prefix => nvl(wwv_flow_application_install.get_image_prefix,'')
,p_documentation_banner=>'Application created from create application wizard 2019.09.02.'
,p_authentication=>'PLUGIN'
,p_authentication_id=>wwv_flow_api.id(65698087598810744)
,p_populate_roles=>'A'
,p_application_tab_set=>0
,p_logo_type=>'T'
,p_logo_text=>'Lumberjack'
,p_app_builder_icon_name=>'app-icon.svg'
,p_public_user=>'APEX_PUBLIC_USER'
,p_proxy_server=>nvl(wwv_flow_application_install.get_proxy,'')
,p_no_proxy_domains=>nvl(wwv_flow_application_install.get_no_proxy_domains,'')
,p_flow_version=>'1.21'
,p_flow_status=>'AVAILABLE_W_EDIT_LINK'
,p_flow_unavailable_text=>'APPLICATION_OFFLINE'
,p_exact_substitutions_only=>'Y'
,p_browser_cache=>'N'
,p_browser_frame=>'D'
,p_deep_linking=>'Y'
,p_runtime_api_usage=>'T'
,p_security_scheme=>'MUST_NOT_BE_PUBLIC_USER'
,p_authorize_batch_job=>'N'
,p_rejoin_existing_sessions=>'N'
,p_csv_encoding=>'Y'
,p_auto_time_zone=>'Y'
,p_email_from=>'jan.kvetina@gmail.com'
,p_substitution_string_01=>'CLEAR_FILTERS'
,p_substitution_value_01=>'<span class="fa fa-refresh fa-flip-horizontal" title="Clear filters"></span>'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210213215724'
,p_file_prefix => nvl(wwv_flow_application_install.get_static_app_file_prefix,'')
,p_files_version=>298
,p_ui_type_name => null
,p_print_server_type=>'INSTANCE'
);
wwv_flow_api.component_end;
end;
/
