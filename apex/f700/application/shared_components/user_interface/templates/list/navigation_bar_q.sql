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
'<li class="ACTIVE #A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_list_template_noncurrent=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="#A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_list_template_name=>'Navigation Bar Q'
,p_internal_name=>'NAVIGATION_BAR_Q'
,p_theme_id=>42
,p_theme_class_id=>20
,p_list_template_before_rows=>'<ul class="NAV_TOP">'
,p_list_template_after_rows=>'</ul>'
,p_before_sub_list=>'<ul>'
,p_after_sub_list=>'</ul></li>'
,p_sub_list_item_current=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="ACTIVE #A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_sub_list_item_noncurrent=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="#A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_item_templ_curr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="ACTIVE #A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
''))
,p_item_templ_noncurr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="#A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
''))
,p_sub_templ_curr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="ACTIVE #A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_sub_templ_noncurr_w_child=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<li class="ACTIVE #A01#">',
'  #A02#<a href="#LINK#" class="#A03#" title="#A04#" #A05#>#A06##TEXT##A07#</a>#A08#',
'</li>'))
,p_a01_label=>'<li class="...">'
,p_a02_label=>'<li>...<a>'
,p_a03_label=>'<a class="..."'
,p_a04_label=>'<a title="..."'
,p_a05_label=>'<a ...>  // javascript onclick'
,p_a06_label=>'<a>... #TEXT</a>'
,p_a07_label=>'<a>#TEXT ...</a>'
,p_a08_label=>'</a>...'
,p_translate_this_template=>'Y'
);
wwv_flow_api.component_end;
end;
/
