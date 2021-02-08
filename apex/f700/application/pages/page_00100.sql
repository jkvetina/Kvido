prompt --application/pages/page_00100
begin
--   Manifest
--     PAGE: 00100
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
 p_id=>100
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'APP NAME [${ENV_NAME}]'
,p_alias=>'HOME'
,p_step_title=>'Home'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210207181134'
);
wwv_flow_api.component_end;
end;
/
