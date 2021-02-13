prompt --application/pages/page_00907
begin
--   Manifest
--     PAGE: 00907
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
 p_id=>907
,p_user_interface_id=>wwv_flow_api.id(63766922917014449)
,p_name=>'Dashboard - Fragmented Tables'
,p_alias=>'FRAGMENTED'
,p_step_title=>'Dashboard - Fragmented Tables'
,p_autocomplete_on_off=>'OFF'
,p_group_id=>wwv_flow_api.id(64766608684607384)
,p_step_template=>wwv_flow_api.id(64127379571157916)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_api.id(63770652250014528)
,p_last_updated_by=>'DEV'
,p_last_upd_yyyymmddhh24miss=>'20210213185652'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(64451420967403434)
,p_plug_name=>'Fragmented Tables'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(64142195941700285)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT',
'    t.table_name,',
'    ROUND(t.blocks * 8, 2) AS fragmented_kb,',
'    ROUND(t.num_rows * t.avg_row_len / 1024, 2) AS actual_kb,',
'    CASE WHEN ROUND(t.blocks * 8, 2) > 0 THEN',
'        ROUND(t.blocks * 8, 2) - ROUND(t.num_rows * t.avg_row_len / 1024, 2) END AS wasted_kb,',
'    CASE WHEN ROUND(t.blocks * 8, 2) > 0 AND ROUND(t.num_rows * t.avg_row_len / 1024, 2) > 0 THEN',
'        FLOOR((ROUND(t.blocks * 8, 2) - ROUND(t.num_rows * t.avg_row_len / 1024, 2)) / ROUND(t.blocks * 8, 2) * 100) END AS wasted_perc,',
'    t.partitioned,',
'    t.temporary,',
'    t.iot_type,',
'    t.row_movement,',
'    i.idx_norm,',
'    i.idx_func,',
'    t.last_analyzed,',
'    t.num_rows,',
'    ''SKRINK'' AS action',
'FROM user_tables t',
'LEFT JOIN (',
'    SELECT',
'        i.table_name,',
'        NULLIF(SUM(CASE WHEN i.index_type LIKE ''NORMAL''    THEN 1 ELSE 0 END), 0) AS idx_norm,',
'        NULLIF(SUM(CASE WHEN i.index_type LIKE ''IOT%''      THEN 1 ELSE 0 END), 0) AS idx_iot,',
'        NULLIF(SUM(CASE WHEN i.index_type LIKE ''FUNCTION%'' THEN 1 ELSE 0 END), 0) AS idx_func',
'    FROM user_indexes i',
'    WHERE i.index_type NOT IN (''LOB'')',
'    GROUP BY i.table_name',
') i ON i.table_name = t.table_name',
'WHERE t.blocks > 0',
'    AND (t.table_name LIKE :P907_TABLE_LIKE || ''%'' OR :P907_TABLE_LIKE IS NULL)',
'ORDER BY 1;'))
,p_plug_source_type=>'NATIVE_IR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_worksheet(
 p_id=>wwv_flow_api.id(64451593278403434)
,p_name=>'Dashboard - Fragmented Tables'
,p_max_row_count_message=>'The maximum row count for this report is #MAX_ROW_COUNT# rows.  Please apply a filter to reduce the number of records in your query.'
,p_no_data_found_message=>'No data found.'
,p_show_nulls_as=>'-'
,p_pagination_type=>'ROWS_X_TO_Y_OF_Z'
,p_pagination_display_pos=>'BOTTOM_RIGHT'
,p_report_list_mode=>'TABS'
,p_show_detail_link=>'N'
,p_download_formats=>'CSV:HTML:EMAIL:XLSX:PDF:RTF'
,p_owner=>'JKVETINA'
,p_internal_uid=>2137199783755843
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64451920098403460)
,p_db_column_name=>'TABLE_NAME'
,p_display_order=>1
,p_column_identifier=>'A'
,p_column_label=>'Table Name'
,p_column_link=>'f?p=&APP_ID.:907:&SESSION.::&DEBUG.:RP:P907_TABLE_LIKE:#TABLE_NAME#'
,p_column_linktext=>'#TABLE_NAME#'
,p_column_link_attr=>'class="FILTER"'
,p_column_type=>'STRING'
,p_heading_alignment=>'LEFT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64452213576403461)
,p_db_column_name=>'FRAGMENTED_KB'
,p_display_order=>2
,p_column_identifier=>'B'
,p_column_label=>'Fragmented Kb'
,p_column_type=>'NUMBER'
,p_heading_alignment=>'RIGHT'
,p_column_alignment=>'RIGHT'
,p_tz_dependent=>'N'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64452658702403463)
,p_db_column_name=>'ACTUAL_KB'
,p_display_order=>3
,p_column_identifier=>'C'
,p_column_label=>'Actual Kb'
,p_column_type=>'NUMBER'
,p_heading_alignment=>'RIGHT'
,p_column_alignment=>'RIGHT'
,p_tz_dependent=>'N'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64457659736667092)
,p_db_column_name=>'WASTED_KB'
,p_display_order=>13
,p_column_identifier=>'G'
,p_column_label=>'Wasted Kb'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458092192667096)
,p_db_column_name=>'WASTED_PERC'
,p_display_order=>23
,p_column_identifier=>'H'
,p_column_label=>'Wasted Perc'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458121087667097)
,p_db_column_name=>'PARTITIONED'
,p_display_order=>43
,p_column_identifier=>'I'
,p_column_label=>'Partitioned'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458279939667098)
,p_db_column_name=>'TEMPORARY'
,p_display_order=>53
,p_column_identifier=>'J'
,p_column_label=>'Temporary'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(70416166740695200)
,p_db_column_name=>'IOT_TYPE'
,p_display_order=>63
,p_column_identifier=>'Q'
,p_column_label=>'IOT'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(70416011723695199)
,p_db_column_name=>'ROW_MOVEMENT'
,p_display_order=>73
,p_column_identifier=>'P'
,p_column_label=>'Row Mov.'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458359515667099)
,p_db_column_name=>'IDX_NORM'
,p_display_order=>83
,p_column_identifier=>'K'
,p_column_label=>'Idx'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458591888667101)
,p_db_column_name=>'IDX_FUNC'
,p_display_order=>93
,p_column_identifier=>'M'
,p_column_label=>'Idx Fn'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458661895667102)
,p_db_column_name=>'LAST_ANALYZED'
,p_display_order=>103
,p_column_identifier=>'N'
,p_column_label=>'Last Analyzed'
,p_column_type=>'DATE'
,p_column_alignment=>'CENTER'
,p_tz_dependent=>'N'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64458725380667103)
,p_db_column_name=>'NUM_ROWS'
,p_display_order=>113
,p_column_identifier=>'O'
,p_column_label=>'Num Rows'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(64362013467509339)
,p_db_column_name=>'ACTION'
,p_display_order=>123
,p_column_identifier=>'E'
,p_column_label=>'Action'
,p_column_link=>'f?p=&APP_ID.:907:&SESSION.::&DEBUG.:RP:P907_SHRINK,P907_TABLE_LIKE:#TABLE_NAME#,#TABLE_NAME#'
,p_column_linktext=>'#ACTION#'
,p_column_type=>'STRING'
,p_column_alignment=>'CENTER'
);
wwv_flow_api.create_worksheet_rpt(
 p_id=>wwv_flow_api.id(64453802675417373)
,p_application_user=>'APXWS_DEFAULT'
,p_report_seq=>10
,p_report_alias=>'21395'
,p_status=>'PUBLIC'
,p_is_default=>'Y'
,p_report_columns=>'TABLE_NAME:FRAGMENTED_KB:ACTUAL_KB:WASTED_KB:WASTED_PERC:PARTITIONED:TEMPORARY:IOT_TYPE:ROW_MOVEMENT:IDX_NORM:IDX_FUNC:LAST_ANALYZED:NUM_ROWS:ACTION:'
,p_sort_column_1=>'NUM_ROWS'
,p_sort_direction_1=>'DESC'
,p_sort_column_2=>'TABLE_NAME'
,p_sort_direction_2=>'ASC'
,p_sort_column_3=>'WASTED_PERC'
,p_sort_direction_3=>'DESC NULLS LAST'
,p_sort_column_4=>'ACTUAL_KB'
,p_sort_direction_4=>'DESC'
,p_sort_column_5=>'0'
,p_sort_direction_5=>'DESC'
,p_sort_column_6=>'0'
,p_sort_direction_6=>'DESC'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(64457990016667095)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(64451420967403434)
,p_button_name=>'RESET'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Reset'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:907:&SESSION.::&DEBUG.:RP:P907_RESET:Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(64709759753340428)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(64451420967403434)
,p_button_name=>'RECALC_STATS'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(63744470351014400)
,p_button_image_alt=>'Recalc Stats'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_redirect_url=>'f?p=&APP_ID.:907:&SESSION.::&DEBUG.:RP:P907_STATS:Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(64361859401509337)
,p_name=>'P907_SHRINK'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(64451420967403434)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(64457703668667093)
,p_name=>'P907_RESET'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(64451420967403434)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(64709836712340429)
,p_name=>'P907_STATS'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(64451420967403434)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(64710118459340432)
,p_name=>'P907_TABLE_LIKE'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(64451420967403434)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(64457873728667094)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'RESET'
,p_process_sql_clob=>'apex.clear_items();'
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(64361974376509338)
,p_process_sequence=>20
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'SHRINK'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'    in_table_name   CONSTANT VARCHAR2(30) := :P907_SHRINK;',
'    q_indexes       VARCHAR2(32767);',
'BEGIN',
'    FOR c IN (',
'        SELECT i.table_name, i.index_name, DBMS_METADATA.GET_DDL(''INDEX'', i.index_name, ''#OWNER#'') AS content',
'        FROM user_indexes i',
'        WHERE i.index_type      LIKE ''FUNCTION%''',
'            AND i.table_name    = in_table_name',
'    ) LOOP',
'        q_indexes := q_indexes || c.content || '';'';',
'    END LOOP;',
'    --',
'    FOR c IN (',
'        SELECT i.table_name, i.index_name',
'        FROM user_indexes i',
'        WHERE i.index_type      LIKE ''FUNCTION%''',
'            AND i.table_name    = in_table_name',
'    ) LOOP',
'        DBMS_OUTPUT.PUT_LINE(''DROP INDEX #OWNER#.'' || c.index_name);',
'        EXECUTE IMMEDIATE ''DROP INDEX #OWNER#.'' || c.index_name;',
'    END LOOP;',
'    --',
'    EXECUTE IMMEDIATE ''ALTER TABLE '' || in_table_name || '' ENABLE ROW MOVEMENT'';',
'    EXECUTE IMMEDIATE ''ALTER TABLE '' || in_table_name || '' SHRINK SPACE'';',
'    EXECUTE IMMEDIATE ''ALTER TABLE '' || in_table_name || '' DISABLE ROW MOVEMENT'';',
'    --',
'    --DBMS_STATS.GATHER_TABLE_STATS(''#OWNER#'', in_table_name);',
'    EXECUTE IMMEDIATE ''ANALYZE TABLE #OWNER#.'' || in_table_name || '' COMPUTE STATISTICS FOR TABLE'';',
'    --',
'    IF q_indexes IS NOT NULL THEN',
'        FOR c IN (',
'            WITH t AS (',
'                SELECT q_indexes AS src FROM DUAL',
'            )',
'            SELECT REGEXP_SUBSTR(src, ''([^;]+)'', 1, LEVEL) AS col',
'            FROM t',
'            CONNECT BY REGEXP_INSTR(src, ''([^;]+)'', 1, LEVEL) > 0',
'            ORDER BY LEVEL ASC',
'        ) LOOP',
'            DBMS_OUTPUT.PUT_LINE(c.col);',
'            EXECUTE IMMEDIATE c.col;',
'        END LOOP;',
'    END IF;',
'EXCEPTION',
'WHEN OTHERS THEN',
'    EXECUTE IMMEDIATE ''ALTER TABLE '' || in_table_name || '' DISABLE ROW MOVEMENT'';',
'    --',
'    RAISE;',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P907_SHRINK'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
,p_security_scheme=>wwv_flow_api.id(64828317424644703)
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(64710004175340431)
,p_process_sequence=>30
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'STATS'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'--DBMS_STATS.GATHER_SCHEMA_STATS(''#OWNER#'');',
'FOR c IN (',
'    SELECT t.table_name',
'    FROM user_tables t',
'    WHERE t.blocks > 0',
'        AND (t.table_name LIKE :P907_TABLE_LIKE || ''%'' OR :P907_TABLE_LIKE IS NULL)',
'    ORDER BY 1',
') LOOP',
'    DBMS_STATS.GATHER_TABLE_STATS(''#OWNER#'', c.table_name);',
'END LOOP;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when=>'P907_STATS'
,p_process_when_type=>'ITEM_IS_NOT_NULL'
,p_security_scheme=>wwv_flow_api.id(64828317424644703)
);
wwv_flow_api.component_end;
end;
/
