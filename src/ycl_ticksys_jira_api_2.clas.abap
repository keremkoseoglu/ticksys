CLASS ycl_ticksys_jira_api_2 DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_ticksys_jira_api.

    METHODS constructor.

  PROTECTED SECTION.
    TYPES string_range TYPE RANGE OF string.

    DATA: jira_def              TYPE REF TO ycl_ticksys_jira_def,
          subtask_parent_rng    TYPE string_range,
          issue_link_parent_rng TYPE string_range.

    METHODS get_location_parent_rng_lazy
      RETURNING VALUE(result) TYPE REF TO string_range.

  PRIVATE SECTION.
    TYPES json_regex_replacement_list TYPE SORTED TABLE OF ytticksys_jijrr
                                      WITH UNIQUE KEY primary_key COMPONENTS replace_order.

    DATA: http_client_factory       TYPE REF TO yif_ticksys_jira_http_clnt_fct,
          lazy_json_regex_reps      TYPE json_regex_replacement_list,
          lazy_json_regex_reps_read TYPE abap_bool,
          status_parent_rng         TYPE string_range,
          location_parent_rng       TYPE string_range,
          location_parent_rng_built TYPE abap_bool.

    METHODS get_http_client_factory_lazy
      RETURNING VALUE(result) TYPE REF TO yif_ticksys_jira_http_clnt_fct.

    METHODS lazy_get_json_regex_reps
      RETURNING VALUE(result) TYPE REF TO json_regex_replacement_list.

ENDCLASS.


CLASS ycl_ticksys_jira_api_2 IMPLEMENTATION.
  METHOD constructor.
    me->status_parent_rng     = VALUE #( option = ycl_addict_toolkit=>option-cp
                                         ( sign = ycl_addict_toolkit=>sign-include
                                           low  = '/*' )
                                         ( sign = ycl_addict_toolkit=>sign-exclude
                                           low  = '/*/*' ) ).

    me->subtask_parent_rng    = VALUE #( option = ycl_addict_toolkit=>option-cp
                                         ( sign = ycl_addict_toolkit=>sign-include
                                           low  = '/issues/*/fields/subtasks/*' )
                                         ( sign = ycl_addict_toolkit=>sign-exclude
                                           low  = '/issues/*/fields/subtasks/*/*' ) ).

    me->issue_link_parent_rng = VALUE #( sign   = ycl_addict_toolkit=>sign-include
                                         option = ycl_addict_toolkit=>option-cp
                                         ( low    = '/issues/*/fields/issuelinks/*/inwardIssue' )
                                         ( low    = '/issues/*/fields/issuelinks/*/outwardIssue' ) ).
  ENDMETHOD.

  METHOD get_http_client_factory_lazy.
    IF me->http_client_factory IS INITIAL.
      me->http_client_factory = CAST #( NEW ycl_ticksys_jira_http_clnt_fct( me->jira_def ) ).
    ENDIF.

    result = me->http_client_factory.
  ENDMETHOD.

  METHOD lazy_get_json_regex_reps.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Caches & returns values from table ytticksys_jijrr
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->lazy_json_regex_reps_read = abap_false.
      SELECT * FROM ytticksys_jijrr "#EC CI_NOFIELD
             WHERE ticsy_id    = @me->jira_def->definitions-ticsy_id
               AND json_regex <> @space
             ORDER BY replace_order
             INTO CORRESPONDING FIELDS OF TABLE @me->lazy_json_regex_reps.

      me->lazy_json_regex_reps_read = abap_true.
    ENDIF.

    result = REF #( me->lazy_json_regex_reps ).
  ENDMETHOD.

  METHOD get_location_parent_rng_lazy.
    result = REF #( me->location_parent_rng ).
    CHECK me->location_parent_rng_built = abap_false.

    " /issues/1/fields/customfield_10139/1
    result->* = VALUE #( FOR _loc IN me->jira_def->location_fields
                         ( sign   = ycl_addict_toolkit=>sign-include
                           option = ycl_addict_toolkit=>option-cp
                           low    = |/issues/1/fields/{ _loc }/*| ) ).

    IF result->* IS INITIAL.
      result->* = VALUE #( ( sign   = ycl_addict_toolkit=>sign-exclude
                             option = ycl_addict_toolkit=>option-cp
                             low    = '*' ) ).
    ENDIF.

    me->location_parent_rng_built = abap_true.
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~search_issues.
    DATA(url) = |{ me->jira_def->definitions-url }/rest/api/2/search| &&
                |?jql={ cl_http_utility=>escape_url( jql ) }| &&
                |&expand=| &&
                |{ COND #( WHEN max_results IS NOT INITIAL THEN |&maxResults={ max_results }| ) }|.

    results = yif_ticksys_jira_api~http_get_jira_rest_api( url ).
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~http_get_jira_rest_api.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Call JIRA REST API via the given URL and return parsed results
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(http_client) = yif_ticksys_jira_api~create_http_client( url ).
    http_client->request->set_method( if_http_request=>co_request_method_get ).

    http_client->send( EXCEPTIONS http_communication_failure = 1
                                  http_invalid_state         = 2
                                  http_processing_failed     = 3
                                  http_invalid_timeout       = 4
                                  OTHERS                     = 5 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( textid   = ycx_ticksys_ticketing_system=>http_request_error
                                                        ticsy_id = me->jira_def->definitions-ticsy_id ).
    ENDIF.

    http_client->receive( EXCEPTIONS http_communication_failure = 1
                                     http_invalid_state         = 2
                                     http_processing_failed     = 3
                                     OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( textid   = ycx_ticksys_ticketing_system=>http_response_error
                                                        ticsy_id = me->jira_def->definitions-ticsy_id ).
    ENDIF.

    http_client->response->get_status( IMPORTING code = DATA(rc) ).
    DATA(response) = http_client->response->get_data( ).
    http_client->close( ).

    IF rc <> yif_ticksys_jira_api=>http_return-ok.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid           = ycx_ticksys_ticketing_system=>unexpected_http_status
                              ticsy_id         = me->jira_def->definitions-ticsy_id
                              http_status_code = rc ).
    ENDIF.

    " Parse """""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(len) = 0.
    DATA(bin) = VALUE yif_ticksys_jira_api=>bin_list( ).

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING buffer        = response
      IMPORTING output_length = len
      TABLES    binary_tab    = bin.

    DATA(json_response) = CONV string( space ).

    CALL FUNCTION 'SCMS_BINARY_TO_STRING'
      EXPORTING  input_length = len
      IMPORTING  text_buffer  = json_response
      TABLES     binary_tab   = bin
      EXCEPTIONS failed       = 1
                 OTHERS       = 2.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid   = ycx_ticksys_ticketing_system=>http_response_parse_error
                              ticsy_id = me->jira_def->definitions-ticsy_id ).
    ENDIF.

    yif_ticksys_jira_api~replace_regex_in_json( CHANGING json = json_response ).
    DATA(parser) = NEW /ui5/cl_json_parser( ).
    parser->parse( json_response ).
    results = parser->m_entries.
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~create_http_client.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates a new HTTP client connecting to Jira
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(http_client_factory) = get_http_client_factory_lazy( ).
    result = http_client_factory->create_default_client( url ).
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~replace_regex_in_json.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Executes regex replacements in table ytticksys_jijrr
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK json IS NOT INITIAL.

    DATA(replacements) = lazy_get_json_regex_reps( ).

    LOOP AT replacements->* REFERENCE INTO DATA(replacement).
      REPLACE ALL OCCURRENCES OF REGEX replacement->json_regex
              IN json WITH replacement->new_json_val IGNORING CASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~set_jira_def.
    me->jira_def = jira_def.
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~get_statuses.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of statuses
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(url)          = |{ me->jira_def->definitions-url }/rest/api/2/status|.
    DATA(api_response) = yif_ticksys_jira_api~http_get_jira_rest_api( url ).

    LOOP AT api_response ASSIGNING FIELD-SYMBOL(<response>)
         WHERE     type     = 1  "#EC CI_SORTSEQ
               AND subtype  = 2
               AND parent  IN me->status_parent_rng.

      CASE <response>-name.
        WHEN 'id'.
          INSERT VALUE #( status_id = <response>-value )
                 INTO TABLE result
                 ASSIGNING FIELD-SYMBOL(<status_cache>).
        WHEN 'name'.
          <status_cache>-status_text = <response>-value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~get_jira_issue.
    " Preparation """""""""""""""""""""""""""""""""""""""""""""""""
    result = VALUE #( ticket_id = ticket_id
                      header    = VALUE #( ticket_id = ticket_id ) ).

    " Search """"""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(search_results) = yif_ticksys_jira_api~search_issues( jql         = |issuekey={ ticket_id }|
                                                               max_results = 1 ).

    " Validate """"""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(total) = VALUE string( search_results[ parent = space
                                                name   = 'total'
                                ]-value OPTIONAL ).

    IF total = space OR total = '0'.
      DATA(ticket_error) = NEW ycx_ticksys_ticket( textid    = ycx_ticksys_ticket=>ticket_not_found
                                                   ticsy_id  = me->jira_def->definitions-ticsy_id
                                                   ticket_id = ticket_id ).

      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid   = ycx_ticksys_ticketing_system=>ycx_ticksys_ticketing_system
                              previous = ticket_error ).
    ENDIF.

    " Read values """""""""""""""""""""""""""""""""""""""""""""""""
    result-header-internal_ticket_id = VALUE #( search_results[ parent = |/issues/1|
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-ticket_description = VALUE #( search_results[ parent = |/issues/1/fields|
                                                                name   = 'summary'
                                                ]-value OPTIONAL ).

    result-header-status_id          = VALUE #( search_results[ parent = '/issues/1/fields/status'
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-status_text        = VALUE #( search_results[ parent = '/issues/1/fields/status'
                                                                name   = 'name'
                                                ]-value OPTIONAL ).

    result-header-completed          = xsdbool( VALUE string( search_results[
                                                                  parent = '/issues/1/fields/status/statusCategory'
                                                                  name   = 'key'
                                                              ]-value OPTIONAL )
                                                = 'done' ).

    result-header-parent_ticket_id   = VALUE #( search_results[ parent = '/issues/1/fields/parent'
                                                                name   = 'key'
                                                ]-value OPTIONAL ).

    result-header-type_id            = VALUE #( search_results[ parent = '/issues/1/fields/issuetype'
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-type_text          = VALUE #( search_results[ parent = '/issues/1/fields/issuetype'
                                                                name   = 'name'
                                                ]-value OPTIONAL ).

    result-header-assignee           = VALUE #( search_results[ parent = '/issues/1/fields/assignee'
                                                                name   = 'name'
                                                ]-value OPTIONAL ).

    result-sub_tickets    = VALUE #( FOR GROUPS _value OF _entry IN search_results "#EC CI_SORTSEQ
                                     WHERE (     parent IN me->subtask_parent_rng
                                             AND name    = 'key' )
                                     GROUP BY _entry-value
                                     ( CONV #( _value ) ) ).

    result-linked_tickets = VALUE #( FOR GROUPS _value OF _entry IN search_results "#EC CI_SORTSEQ
                                     WHERE (     parent IN me->issue_link_parent_rng
                                             AND name    = 'key' )
                                     GROUP BY _entry-value
                                     ( CONV #( _value ) ) ).

    LOOP AT me->jira_def->status_assignee_fields
         INTO DATA(_jsaf)
         GROUP BY ( jira_field = _jsaf-jira_field )
         ASSIGNING FIELD-SYMBOL(<jsaf>).

      DATA(assignee_found) = abap_false.

      LOOP AT search_results REFERENCE INTO DATA(assignee_result)
           WHERE     parent  = |/issues/1/fields/{ <jsaf>-jira_field }|
                 AND name    = me->jira_def->definitions-assignee_fld
                 AND value  <> yif_ticksys_jira_api=>json_null.

        INSERT VALUE yif_ticksys_jira_api=>custom_field_value_dict( jira_field = <jsaf>-jira_field
                                                                    value      = assignee_result->value )
               INTO TABLE result-custom_fields.

        assignee_found = abap_true.
        EXIT.
      ENDLOOP.

      CHECK assignee_found = abap_true.
      EXIT.
    ENDLOOP.

    LOOP AT me->jira_def->transport_instruction_fields ASSIGNING FIELD-SYMBOL(<tif>).
      ASSIGN search_results[ parent = |/issues/1/fields|
                             name   = <tif> ]
             TO FIELD-SYMBOL(<tif_value>).

      CHECK     sy-subrc           = 0
            AND <tif_value>-value IS NOT INITIAL
            AND <tif_value>-value <> yif_ticksys_jira_api=>json_null.

      result-transport_instructions =
        |{ result-transport_instructions }| &&
        |{ COND #( WHEN result-transport_instructions IS NOT INITIAL THEN ` ` ) }| &&
        |{ <tif_value>-value }|.
    ENDLOOP.

    LOOP AT me->jira_def->tcode_fields ASSIGNING FIELD-SYMBOL(<tcf>).
      APPEND LINES OF VALUE yif_ticksys_ticketing_system=>tcode_list( FOR _entry IN search_results
                                                                      WHERE (     parent  = |/issues/1/fields/{ <tcf> }|
                                                                              AND value  <> yif_ticksys_jira_api=>json_null )
                                                                      ( CONV #( _entry-value ) ) )
             TO result-tcodes.
    ENDLOOP.

    LOOP AT me->jira_def->main_module_fields ASSIGNING FIELD-SYMBOL(<mm>).
      DATA(mm_parent) = |/issues/1/fields/{ <mm> }|.

      LOOP AT search_results ASSIGNING FIELD-SYMBOL(<mm_result>)
           WHERE     parent  = mm_parent
                 AND value  IS NOT INITIAL.

        CASE <mm_result>-name.
          WHEN `id`. result-header-main_module_id   = <mm_result>-value.
          WHEN `value`. result-header-main_module_text = <mm_result>-value.
        ENDCASE.
      ENDLOOP.
    ENDLOOP.

    LOOP AT me->jira_def->platform_fields ASSIGNING FIELD-SYMBOL(<plf>).
      APPEND LINES OF VALUE yif_ticksys_ticketing_system=>tcode_list( FOR _entry IN search_results
                                                                      WHERE (     parent  = |/issues/1/fields/{ <plf> }|
                                                                              AND name    = 'value'
                                                                              AND value  <> yif_ticksys_jira_api=>json_null )
                                                                      ( CONV #( _entry-value ) ) )
             TO result-platforms.
    ENDLOOP.

    result-header-platform = VALUE #( result-platforms[ 1 ] OPTIONAL ).

    DATA(location_parent_rng) = get_location_parent_rng_lazy( ).

    LOOP AT search_results REFERENCE INTO DATA(location_value)
         WHERE     parent IN location_parent_rng->* "#EC CI_SORTSEQ
               AND name    = 'value'
               AND value  IS NOT INITIAL
               AND value  <> yif_ticksys_jira_api=>json_null.

      result-header-location =
        |{ result-header-location }| &&
        |{ COND #( WHEN result-header-location IS NOT INITIAL THEN ` ` ) }| &&
        |{ location_value->value }|.
    ENDLOOP.

    SORT result-linked_tickets.
    DELETE ADJACENT DUPLICATES FROM result-linked_tickets.

    SORT result-sub_tickets.
    DELETE ADJACENT DUPLICATES FROM result-sub_tickets.

    SORT result-tcodes.
    DELETE ADJACENT DUPLICATES FROM result-tcodes.
  ENDMETHOD.
ENDCLASS.
