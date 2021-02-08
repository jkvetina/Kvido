prompt --application/shared_components/user_interface/templates/region/interactive_report_q
begin
--   Manifest
--     REGION TEMPLATE: INTERACTIVE_REPORT_Q
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_plug_template(
 p_id=>wwv_flow_api.id(64142195941700285)
,p_layout=>'TABLE'
,p_template=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div id="#REGION_STATIC_ID#" #REGION_ATTRIBUTES# class="t-IRR-region #REGION_CSS_CLASSES#">',
'  <h2 id="#REGION_STATIC_ID#_heading" class="report_header">#TITLE#</h2>',
'#PREVIOUS##BODY##SUB_REGIONS##NEXT#',
'</div>'))
,p_page_plug_template_name=>'Interactive Report Q'
,p_internal_name=>'INTERACTIVE_REPORT_Q'
,p_theme_id=>42
,p_theme_class_id=>9
,p_default_label_alignment=>'RIGHT'
,p_default_field_alignment=>'LEFT'
,p_translate_this_template=>'N'
);
wwv_flow_api.component_end;
end;
/
