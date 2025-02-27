CLASS ycl_ticksys_jira_reader DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES string_range TYPE RANGE OF string.

    TYPES status_set   TYPE HASHED TABLE OF yif_ticksys_ticketing_system=>status_dict
          WITH UNIQUE KEY primary_key COMPONENTS status_id.

    TYPES: BEGIN OF custom_field_value_dict,
             jira_field TYPE yd_ticksys_jira_field,
             value      TYPE string,
           END OF custom_field_value_dict,

           custom_field_value_set TYPE HASHED TABLE OF custom_field_value_dict
           WITH UNIQUE KEY primary_key COMPONENTS jira_field.

    TYPES: BEGIN OF issue_dict,
             ticket_id              TYPE ysticksys_ticket_header-ticket_id,
             header                 TYPE ysticksys_ticket_header,
             custom_fields          TYPE custom_field_value_set,
             sub_tickets            TYPE yif_ticksys_ticketing_system=>ticket_id_list,
             linked_tickets         TYPE yif_ticksys_ticketing_system=>ticket_id_list,
             tcodes                 TYPE yif_ticksys_ticketing_system=>tcode_list,
             transport_instructions TYPE string,
           END OF issue_dict.

    DATA subtask_parent_rng    TYPE string_range READ-ONLY.
    DATA issue_link_parent_rng TYPE string_range READ-ONLY.
    DATA issue_key_parent_rng  TYPE string_range READ-ONLY.
    DATA status_parent_rng     TYPE string_range READ-ONLY.

    CLASS-METHODS get_instance
      IMPORTING ticsy_id      TYPE yd_ticksys_ticsy_id
      RETURNING VALUE(result) TYPE REF TO ycl_ticksys_jira_reader
      RAISING   ycx_addict_table_content.

    METHODS create_http_client
      IMPORTING url           TYPE clike
      RETURNING VALUE(result) TYPE REF TO if_http_client
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_statuses
      RETURNING VALUE(statuses) TYPE status_set
      RAISING   ycx_ticksys_ticketing_system.

    METHODS search_issues
      IMPORTING jql            TYPE string
                max_results    TYPE i OPTIONAL
      RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_jira_issue
      IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
                bypass_cache  TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(output) TYPE issue_dict
      RAISING   ycx_ticksys_ticketing_system.

  PRIVATE SECTION.
    TYPES issue_set TYPE HASHED TABLE OF issue_dict
           WITH UNIQUE KEY primary_key COMPONENTS ticket_id.

    TYPES: BEGIN OF bin_dict,
             line TYPE x LENGTH 255,
           END OF bin_dict,

           bin_list TYPE STANDARD TABLE OF bin_dict WITH EMPTY KEY.

    TYPES json_regex_replacement_list TYPE SORTED TABLE OF ytticksys_jijrr
          WITH UNIQUE KEY primary_key COMPONENTS replace_order.

    TYPES: BEGIN OF multiton_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
             obj      TYPE REF TO ycl_ticksys_jira_reader,
           END OF multiton_dict,

           multiton_set TYPE HASHED TABLE OF multiton_dict WITH UNIQUE KEY primary_key COMPONENTS ticsy_id.

    CONSTANTS json_null TYPE text4 VALUE 'null'.

    CONSTANTS: BEGIN OF http_return,
                 ok TYPE i VALUE 200,
               END OF http_return.

    CLASS-DATA multitons TYPE multiton_set.

    DATA: defs                      TYPE REF TO ycl_ticksys_jira_def,
          issue_cache               TYPE issue_set,
          status_cache              TYPE status_set,
          lazy_json_regex_reps      TYPE json_regex_replacement_list,
          lazy_json_regex_reps_read TYPE abap_bool,
          http_client_factory       TYPE REF TO yif_ticksys_jira_http_clnt_fct,
          location_parent_rng       TYPE string_range,
          location_parent_rng_built TYPE abap_bool.

    METHODS constructor
      IMPORTING ticsy_id TYPE yd_ticksys_ticsy_id
      RAISING   ycx_addict_table_content.

    METHODS http_get_jira_rest_api
      IMPORTING url            TYPE string
      RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
      RAISING   ycx_ticksys_ticketing_system.

    METHODS lazy_get_json_regex_reps
      RETURNING VALUE(result) TYPE REF TO json_regex_replacement_list.

    METHODS replace_regex_in_json
      CHANGING json TYPE string.

    METHODS get_http_client_factory_lazy
      RETURNING VALUE(result) TYPE REF TO yif_ticksys_jira_http_clnt_fct.

    METHODS get_location_parent_rng_lazy
      RETURNING VALUE(result) TYPE REF TO string_range.
ENDCLASS.


CLASS ycl_ticksys_jira_reader IMPLEMENTATION.
  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Initial object access
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    me->defs                  = ycl_ticksys_jira_def=>get_instance( ticsy_id ).

    me->subtask_parent_rng    = VALUE #( option = ycl_addict_toolkit=>option-cp
                                         ( sign = ycl_addict_toolkit=>sign-include
                                           low  = '/issues/*/fields/subtasks/*' )
                                         ( sign = ycl_addict_toolkit=>sign-exclude
                                           low  = '/issues/*/fields/subtasks/*/*' ) ).

    me->issue_link_parent_rng = VALUE #( sign   = ycl_addict_toolkit=>sign-include
                                         option = ycl_addict_toolkit=>option-cp
                                         ( low    = '/issues/*/fields/issuelinks/*/inwardIssue' )
                                         ( low    = '/issues/*/fields/issuelinks/*/outwardIssue' ) ).

    me->issue_key_parent_rng  = VALUE #( option = ycl_addict_toolkit=>option-cp
                                         ( sign = ycl_addict_toolkit=>sign-include
                                           low  = '/issues/*' )
                                         ( sign = ycl_addict_toolkit=>sign-exclude
                                           low  = '/issues/*/*' ) ).

    me->status_parent_rng     = VALUE #( option = ycl_addict_toolkit=>option-cp
                                         ( sign = ycl_addict_toolkit=>sign-include
                                           low  = '/*' )
                                         ( sign = ycl_addict_toolkit=>sign-exclude
                                           low  = '/*/*' ) ).
  ENDMETHOD.

  METHOD create_http_client.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates a new HTTP client connecting to Jira
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(http_client_factory) = get_http_client_factory_lazy( ).
    result = http_client_factory->create_default_client( url ).
  ENDMETHOD.

  METHOD get_instance.
    TRY.
        DATA(mt) = REF #( multitons[ KEY primary_key
                                     ticsy_id = ticsy_id ] ).
      CATCH cx_sy_itab_line_not_found.
        INSERT VALUE #( ticsy_id = ticsy_id
                        obj      = NEW #( ticsy_id ) )
               INTO TABLE multitons REFERENCE INTO mt.
    ENDTRY.

    result = mt->obj.
  ENDMETHOD.

  METHOD get_jira_issue.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads the given Jira issue from the server
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF bypass_cache = abap_true.
      DELETE me->issue_cache WHERE ticket_id = ticket_id.
    ENDIF.

    ASSIGN me->issue_cache[ KEY primary_key COMPONENTS ticket_id = ticket_id ]
           TO FIELD-SYMBOL(<cache>).

    IF sy-subrc <> 0.
      " Preparation """""""""""""""""""""""""""""""""""""""""""""""""
      DATA(cache) = VALUE issue_dict( ticket_id = ticket_id
                                      header    = VALUE #( ticket_id = ticket_id ) ).

      " Search """"""""""""""""""""""""""""""""""""""""""""""""""""""
      DATA(results) = search_issues( jql         = |issuekey={ ticket_id }|
                                     max_results = 1 ).

      " Validate """"""""""""""""""""""""""""""""""""""""""""""""""""
      DATA(total) = VALUE string( results[ parent = space
                                           name   = 'total'
                                  ]-value OPTIONAL ).

      IF total = space OR total = '0'.
        DATA(ticket_error) = NEW ycx_ticksys_ticket( textid    = ycx_ticksys_ticket=>ticket_not_found
                                                     ticsy_id  = me->defs->definitions-ticsy_id
                                                     ticket_id = ticket_id ).

        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                                textid   = ycx_ticksys_ticketing_system=>ycx_ticksys_ticketing_system
                                previous = ticket_error ).
      ENDIF.

      " Read values """""""""""""""""""""""""""""""""""""""""""""""""
      cache-header-internal_ticket_id = VALUE #( results[ parent = |/issues/1|
                                                          name   = 'id'
                                                 ]-value OPTIONAL ).

      cache-header-ticket_description = VALUE #( results[ parent = |/issues/1/fields|
                                                          name   = 'summary'
                                                 ]-value OPTIONAL ).

      cache-header-status_id          = VALUE #( results[ parent = '/issues/1/fields/status'
                                                          name   = 'id'
                                                 ]-value OPTIONAL ).

      cache-header-status_text        = VALUE #( results[ parent = '/issues/1/fields/status'
                                                          name   = 'name'
                                                 ]-value OPTIONAL ).

      cache-header-completed          = xsdbool( VALUE string( results[
                                                                   parent = '/issues/1/fields/status/statusCategory'
                                                                   name   = 'key'
                                                               ]-value OPTIONAL )
                                                 = 'done' ).

      cache-header-parent_ticket_id   = VALUE #( results[ parent = '/issues/1/fields/parent'
                                                          name   = 'key'
                                                 ]-value OPTIONAL ).

      cache-header-type_id            = VALUE #( results[ parent = '/issues/1/fields/issuetype'
                                                          name   = 'id'
                                                 ]-value OPTIONAL ).

      cache-header-type_text          = VALUE #( results[ parent = '/issues/1/fields/issuetype'
                                                          name   = 'name'
                                                 ]-value OPTIONAL ).

      cache-header-assignee           = VALUE #( results[ parent = '/issues/1/fields/assignee'
                                                          name   = 'name'
                                                 ]-value OPTIONAL ).

      cache-sub_tickets    = VALUE #( FOR GROUPS _value OF _entry IN results "#EC CI_SORTSEQ
                                      WHERE (     parent IN me->subtask_parent_rng
                                              AND name    = 'key' )
                                      GROUP BY _entry-value
                                      ( CONV #( _value ) ) ).

      cache-linked_tickets = VALUE #( FOR GROUPS _value OF _entry IN results "#EC CI_SORTSEQ
                                      WHERE (     parent IN me->issue_link_parent_rng
                                              AND name    = 'key' )
                                      GROUP BY _entry-value
                                      ( CONV #( _value ) ) ).

      LOOP AT me->defs->status_assignee_fields
           INTO DATA(_jsaf)
           GROUP BY ( jira_field = _jsaf-jira_field )
           ASSIGNING FIELD-SYMBOL(<jsaf>).

        DATA(assignee_found) = abap_false.

        LOOP AT results REFERENCE INTO DATA(assignee_result)
             WHERE     parent  = |/issues/1/fields/{ <jsaf>-jira_field }|
                   AND name    = me->defs->definitions-assignee_fld
                   AND value  <> me->json_null.

          INSERT VALUE custom_field_value_dict( jira_field = <jsaf>-jira_field
                                                value      = assignee_result->value )
                 INTO TABLE cache-custom_fields.

          assignee_found = abap_true.
          EXIT.
        ENDLOOP.

        CHECK assignee_found = abap_true.
        EXIT.
      ENDLOOP.

      LOOP AT me->defs->transport_instruction_fields ASSIGNING FIELD-SYMBOL(<tif>).
        ASSIGN results[ parent = |/issues/1/fields|
                        name   = <tif> ]
               TO FIELD-SYMBOL(<tif_value>).

        CHECK     sy-subrc           = 0
              AND <tif_value>-value IS NOT INITIAL
              AND <tif_value>-value <> me->json_null.

        cache-transport_instructions =
          |{ cache-transport_instructions }| &&
          |{ COND #( WHEN cache-transport_instructions IS NOT INITIAL THEN ` ` ) }| &&
          |{ <tif_value>-value }|.
      ENDLOOP.

      LOOP AT me->defs->tcode_fields ASSIGNING FIELD-SYMBOL(<tcf>).
        APPEND LINES OF VALUE yif_ticksys_ticketing_system=>tcode_list( FOR _entry IN results
                                                                        WHERE (     parent  = |/issues/1/fields/{ <tcf> }|
                                                                                AND value  <> me->json_null )
                                                                        ( CONV #( _entry-value ) ) )
               TO cache-tcodes.
      ENDLOOP.

      LOOP AT me->defs->main_module_fields ASSIGNING FIELD-SYMBOL(<mm>).
        DATA(mm_parent) = |/issues/1/fields/{ <mm> }|.

        LOOP AT results ASSIGNING FIELD-SYMBOL(<mm_result>)
             WHERE     parent  = mm_parent
                   AND value  IS NOT INITIAL.

          CASE <mm_result>-name.
            WHEN `id`. cache-header-main_module_id   = <mm_result>-value.
            WHEN `value`. cache-header-main_module_text = <mm_result>-value.
          ENDCASE.
        ENDLOOP.
      ENDLOOP.

      DATA(location_parent_rng) = get_location_parent_rng_lazy( ).

      LOOP AT results REFERENCE INTO DATA(location_value)
           WHERE     parent IN location_parent_rng->*
                 AND name    = 'value'
                 AND value  IS NOT INITIAL
                 AND value  <> me->json_null.

        cache-header-location =
          |{ cache-header-location }| &&
          |{ COND #( WHEN cache-header-location IS NOT INITIAL THEN ` ` ) }| &&
          |{ location_value->value }|.
      ENDLOOP.

      SORT cache-linked_tickets.
      DELETE ADJACENT DUPLICATES FROM cache-linked_tickets.

      SORT cache-sub_tickets.
      DELETE ADJACENT DUPLICATES FROM cache-sub_tickets.

      SORT cache-tcodes.
      DELETE ADJACENT DUPLICATES FROM cache-tcodes.

      " Flush """""""""""""""""""""""""""""""""""""""""""""""""""""""
      INSERT cache INTO TABLE me->issue_cache ASSIGNING <cache>.
    ENDIF.

    output = <cache>.
  ENDMETHOD.

  METHOD get_statuses.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of statuses
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->status_cache IS INITIAL.
      DATA(url) = |{ me->defs->definitions-url }/rest/api/2/status|.
      DATA(api_response) = http_get_jira_rest_api( url ).

      LOOP AT api_response ASSIGNING FIELD-SYMBOL(<response>)
           WHERE     type     = 1  "#EC CI_SORTSEQ
                 AND subtype  = 2
                 AND parent  IN me->status_parent_rng.

        CASE <response>-name.
          WHEN 'id'.
            INSERT VALUE #( status_id = <response>-value )
                   INTO TABLE me->status_cache
                   ASSIGNING FIELD-SYMBOL(<status_cache>).
          WHEN 'name'.
            <status_cache>-status_text = <response>-value.
        ENDCASE.
      ENDLOOP.
    ENDIF.

    statuses = me->status_cache.
  ENDMETHOD.

  METHOD http_get_jira_rest_api.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Call JIRA REST API via the given URL and return parsed results
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(http_client) = create_http_client( url ).
    http_client->request->set_method( if_http_request=>co_request_method_get ).

    http_client->send( EXCEPTIONS http_communication_failure = 1
                                  http_invalid_state         = 2
                                  http_processing_failed     = 3
                                  http_invalid_timeout       = 4
                                  OTHERS                     = 5 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( textid   = ycx_ticksys_ticketing_system=>http_request_error
                                                        ticsy_id = me->defs->definitions-ticsy_id ).
    ENDIF.

    http_client->receive( EXCEPTIONS http_communication_failure = 1
                                     http_invalid_state         = 2
                                     http_processing_failed     = 3
                                     OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( textid   = ycx_ticksys_ticketing_system=>http_response_error
                                                        ticsy_id = me->defs->definitions-ticsy_id ).
    ENDIF.

    http_client->response->get_status( IMPORTING code = DATA(rc) ).
    DATA(response) = http_client->response->get_data( ).
    http_client->close( ).

    IF rc <> me->http_return-ok.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid           = ycx_ticksys_ticketing_system=>unexpected_http_status
                              ticsy_id         = me->defs->definitions-ticsy_id
                              http_status_code = rc ).
    ENDIF.

    " Parse """""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(len) = 0.
    DATA(bin) = VALUE bin_list( ).

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
                              ticsy_id = me->defs->definitions-ticsy_id ).
    ENDIF.

    replace_regex_in_json( CHANGING json = json_response ).
    DATA(parser) = NEW /ui5/cl_json_parser( ).
    parser->parse( json_response ).
    results = parser->m_entries.
  ENDMETHOD.

  METHOD search_issues.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Runs a JQL search over Jira API
    " Full expand list if needed:
    " 'names,renderedFields,schema,transitions,operations,editmeta,changelog'
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(url) = |{ me->defs->definitions-url }/rest/api/2/search| &&
                |?jql={ cl_http_utility=>escape_url( jql ) }| &&
                |&expand=| &&
                |{ COND #( WHEN max_results IS NOT INITIAL THEN |&maxResults={ max_results }| ) }|.

    results = http_get_jira_rest_api( url ).
  ENDMETHOD.

  METHOD lazy_get_json_regex_reps.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Caches & returns values from table ytticksys_jijrr
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->lazy_json_regex_reps_read = abap_false.
      SELECT * FROM ytticksys_jijrr "#EC CI_NOFIELD
             WHERE ticsy_id    = @me->defs->definitions-ticsy_id
               AND json_regex <> @space
             ORDER BY replace_order
             INTO CORRESPONDING FIELDS OF TABLE @me->lazy_json_regex_reps.

      me->lazy_json_regex_reps_read = abap_true.
    ENDIF.

    result = REF #( me->lazy_json_regex_reps ).
  ENDMETHOD.

  METHOD replace_regex_in_json.
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

  METHOD get_http_client_factory_lazy.
    IF me->http_client_factory IS INITIAL.
      me->http_client_factory = CAST #( NEW ycl_ticksys_jira_http_clnt_fct( me->defs ) ).
    ENDIF.

    result = me->http_client_factory.
  ENDMETHOD.

  METHOD get_location_parent_rng_lazy.
    result = REF #( me->location_parent_rng ).
    CHECK me->location_parent_rng_built = abap_false.

    " /issues/1/fields/customfield_10139/1
    result->* = VALUE #( FOR _loc IN me->defs->location_fields
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
ENDCLASS.
