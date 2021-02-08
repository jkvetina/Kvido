prompt --application/shared_components/user_interface/lovs/view_as_report_chart
begin
--   Manifest
--     VIEW_AS_REPORT_CHART
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>9526531750928358
,p_default_application_id=>700
,p_default_id_offset=>28323188538908472
,p_default_owner=>'DEV'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(63845351490014900)
,p_lov_name=>'VIEW_AS_REPORT_CHART'
,p_lov_query=>'.'||wwv_flow_api.id(63845351490014900)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(63845628397014901)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Add Report Page'
,p_lov_return_value=>'REPORT'
,p_lov_template=>'<span class="fa fa-table" aria-hidden="true"></span><span class="u-VisuallyHidden">#DISPLAY_VALUE#</span>'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(63846051024014901)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Add Chart Page'
,p_lov_return_value=>'CHART'
,p_lov_template=>'<span class="fa fa-pie-chart" aria-hidden="true"></span><span class="u-VisuallyHidden">#DISPLAY_VALUE#</span>'
);
wwv_flow_api.component_end;
end;
/
