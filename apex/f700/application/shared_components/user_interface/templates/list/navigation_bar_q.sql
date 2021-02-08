prompt --application/shared_components/user_interface/templates/list/navigation_bar_q
begin
--   Manifest
--     REGION TEMPLATE: NAVIGATION_BAR_Q
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_list_template(
 p_id=>wwv_flow_api.id(64163400516768059)
,p_list_template_current=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="active #A02#">',
'  <a href="#LINK#" class="#A03#">#TEXT#</a>',
'</li>'))
,p_list_template_noncurrent=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="#A02#">',
'  <a href="#LINK#" class="#A03#">#TEXT#</a>',
'</li>'))
,p_list_template_name=>'Navigation Bar Q'
,p_internal_name=>'NAVIGATION_BAR_Q'
,p_theme_id=>42
,p_theme_class_id=>20
,p_list_template_before_rows=>'<ul class="NAV_LEFT NAV_RIGHT">'
,p_list_template_after_rows=>'</ul>'
,p_before_sub_list=>'<ul>'
,p_after_sub_list=>'</ul></li>'
,p_sub_list_item_current=>'<li class="active #A02#"><a href="#LINK#" class="#A03#">#TEXT#</a></li>'
,p_sub_list_item_noncurrent=>'<li class="#A02#"><a href="#LINK#" class="#A03#">#TEXT#</a></li>'
,p_item_templ_curr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="active #A02#">',
'  <a href="#LINK#" class="#A03#">#TEXT#</a>',
''))
,p_item_templ_noncurr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="#A02#">',
'  <a href="#LINK#" class="#A03#">#TEXT#</a>',
''))
,p_sub_templ_curr_w_child=>'<li class="active #A02#"><a href="#LINK#" class="#A03#">#TEXT#</a></li>'
,p_sub_templ_noncurr_w_child=>'<li class="#A02#"><a href="#LINK#" class="#A03#">#TEXT#</a></li>'
,p_a01_label=>'Badge Value'
,p_a02_label=>'List Item CSS Classes'
,p_a03_label=>'Anchor Class (icon)'
,p_translate_this_template=>'Y'
);
wwv_flow_api.component_end;
end;
/
