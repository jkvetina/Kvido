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
,p_alias=>'FILES'
,p_step_title=>'Uploaded Files'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(10819719419852508)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210211105923'
);
wwv_flow_api.component_end;
end;
/
