CLASS ycl_ticksys_jira_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES string_range TYPE RANGE OF string.

    TYPES status_set TYPE HASHED TABLE OF yif_addict_ticketing_system=>status_dict
          WITH UNIQUE KEY primary_key COMPONENTS status_id.

    TYPES: BEGIN OF custom_field_value_dict,
             jira_field TYPE yd_ticksys_jira_field,
             value      TYPE string,
           END OF custom_field_value_dict,

           custom_field_value_set TYPE HASHED TABLE OF custom_field_value_dict
           WITH UNIQUE KEY primary_key COMPONENTS jira_field.

    TYPES: BEGIN OF issue_dict,
             ticket_id              TYPE ysaddict_ticket_header-ticket_id,
             header                 TYPE ysaddict_ticket_header,
             custom_fields          TYPE custom_field_value_set,
             sub_tickets            TYPE yif_addict_ticketing_system=>ticket_id_list,
             linked_tickets         TYPE yif_addict_ticketing_system=>ticket_id_list,
             tcodes                 TYPE yif_addict_ticketing_system=>tcode_list,
             transport_instructions TYPE string,
           END OF issue_dict.

    DATA subtask_parent_rng TYPE string_range READ-ONLY.
    DATA issue_link_parent_rng TYPE string_range READ-ONLY.
    DATA issue_key_parent_rng TYPE string_range READ-ONLY.
    DATA status_parent_rng TYPE string_range READ-ONLY.

    CLASS-METHODS get_instance
      RETURNING VALUE(instance) TYPE REF TO ycl_ticksys_jira_reader
      RAISING   ycx_addict_table_content.

    METHODS create_http_client
      IMPORTING !url               TYPE clike
      RETURNING VALUE(http_client) TYPE REF TO if_http_client
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_statuses
      RETURNING VALUE(statuses) TYPE status_set
      RAISING   ycx_ticksys_ticketing_system..

    METHODS search_issues
      IMPORTING !jql           TYPE string
                !max_results   TYPE i OPTIONAL
      RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_jira_issue
      IMPORTING !ticket_id    TYPE yd_addict_ticket_id
                !bypass_cache TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(output) TYPE issue_dict
      RAISING   ycx_ticksys_ticketing_system.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES  issue_set TYPE HASHED TABLE OF issue_dict
           WITH UNIQUE KEY primary_key COMPONENTS ticket_id.

    TYPES: BEGIN OF bin_dict,
             line TYPE x LENGTH 255,
           END OF bin_dict,

           bin_list TYPE STANDARD TABLE OF bin_dict WITH EMPTY KEY.

    constants json_null type text4 value 'null'.

    CONSTANTS: BEGIN OF http_return,
                 ok TYPE i VALUE 200,
               END OF http_return.

    CLASS-DATA singleton TYPE REF TO ycl_ticksys_jira_reader.

    DATA defs TYPE REF TO ycl_ticksys_jira_def.
    DATA issue_cache TYPE issue_set.
    DATA status_cache TYPE status_set.

    METHODS constructor RAISING ycx_addict_table_content.

    METHODS http_get_jira_rest_api
      IMPORTING !url           TYPE string
      RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
      RAISING   ycx_ticksys_ticketing_system.
ENDCLASS.



CLASS ycl_ticksys_jira_reader IMPLEMENTATION.
  METHOD get_instance.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns singleton instance
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    instance = ycl_ticksys_jira_reader=>singleton.

    IF instance IS INITIAL.
      instance = NEW #( ).
    ENDIF.
  ENDMETHOD.


  METHOD create_http_client.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates a new HTTP client connecting to Jira
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    cl_http_client=>create_by_url(
      EXPORTING url    = CONV #( url )
      IMPORTING client = http_client
      EXCEPTIONS argument_not_found = 1
                 plugin_not_active  = 2
                 internal_error     = 3
                 OTHERS             = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
        EXPORTING
          textid   = ycx_ticksys_ticketing_system=>http_client_creation_error
          ticsy_id = ycl_ticksys_jira=>ticsy_id.
    ENDIF.

    http_client->request->set_version( if_http_request=>co_protocol_version_1_0 ).

    http_client->authenticate(
        username = CONV #( me->defs->definitions-username )
        password = CONV #( me->defs->definitions-password ) ).
  ENDMETHOD.


  METHOD get_statuses.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of statuses
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->status_cache IS INITIAL.
      DATA(url) = |{ me->defs->definitions-url }/rest/api/2/status|.
      DATA(api_response) = http_get_jira_rest_api( url ).

      LOOP AT api_response ASSIGNING FIELD-SYMBOL(<response>)
              WHERE type    = 1 AND
                    subtype = 2 AND
                    parent IN me->status_parent_rng.

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


  METHOD get_jira_issue.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads the given Jira issue from the server
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF bypass_cache = abap_true.
      DELETE me->issue_cache WHERE ticket_id = ticket_id.
    ENDIF.

    ASSIGN me->issue_cache[ KEY primary_key COMPONENTS
                            ticket_id = ticket_id ]
           TO FIELD-SYMBOL(<cache>).

    IF sy-subrc <> 0.
      " Preparation """""""""""""""""""""""""""""""""""""""""""""""""
      DATA(cache) = VALUE issue_dict( ticket_id = ticket_id
                                      header    = VALUE #( ticket_id = ticket_id ) ).

      " Search """"""""""""""""""""""""""""""""""""""""""""""""""""""
      DATA(results) = search_issues( jql         = |issuekey={ ticket_id }|
                                     max_results = 1 ).

      " Read values """""""""""""""""""""""""""""""""""""""""""""""""
      cache-header-ticket_description = VALUE #( results[ parent = |/issues/1/fields|
                                                          name   = 'summary'
                                                        ]-value OPTIONAL ).

      cache-header-status_id = VALUE #( results[ parent = '/issues/1/fields/status'
                                                 name   = 'id'
                                               ]-value OPTIONAL ).

      cache-header-status_text = VALUE #( results[ parent = '/issues/1/fields/status'
                                                   name   = 'name'
                                                 ]-value OPTIONAL ).

      cache-header-completed = xsdbool( VALUE string( results[ parent = '/issues/1/fields/status/statusCategory'
                                                               name   = 'key'
                                                             ]-value OPTIONAL
                                                     ) = 'done' ).

      cache-header-parent_ticket_id = VALUE #( results[ parent = '/issues/1/fields/parent'
                                                        name   = 'key'
                                                      ]-value OPTIONAL ).

      cache-header-type_id = VALUE #( results[ parent = '/issues/1/fields/issuetype'
                                               name   = 'id'
                                             ]-value OPTIONAL ).

      cache-header-type_text = VALUE #( results[ parent = '/issues/1/fields/issuetype'
                                                 name   = 'name'
                                               ]-value OPTIONAL ).

      cache-sub_tickets = VALUE #( FOR GROUPS _value OF _entry IN results "#EC CI_SORTSEQ
                                   WHERE ( parent IN me->subtask_parent_rng AND
                                           name = 'key' )
                                   GROUP BY _entry-value
                                   ( CONV #( _value ) ) ).

      cache-linked_tickets = VALUE #( FOR GROUPS _value OF _entry IN results "#EC CI_SORTSEQ
                                      WHERE ( parent IN me->issue_link_parent_rng AND
                                              name = 'key' )
                                      GROUP BY _entry-value
                                      ( CONV #( _value ) ) ).

      LOOP AT me->defs->status_assignee_fields
              INTO DATA(_jsaf)
              GROUP BY ( jira_field = _jsaf-jira_field )
              ASSIGNING FIELD-SYMBOL(<jsaf>).

        ASSIGN results[ parent = |/issues/1/fields/{ <jsaf>-jira_field }|
                        name   = 'name' ]
               TO FIELD-SYMBOL(<custom_field>).

        CHECK sy-subrc = 0 and
              <custom_Field>-value <> me->json_null.

        INSERT VALUE custom_field_value_dict(
                       jira_field = <jsaf>-jira_field
                       value      = <custom_field>-value )
               INTO TABLE cache-custom_fields.
      ENDLOOP.

      LOOP AT me->defs->transport_instruction_fields ASSIGNING FIELD-SYMBOL(<tif>).
        ASSIGN results[ parent = |/issues/1/fields|
                        name   = <tif> ]
               TO FIELD-SYMBOL(<tif_value>).

        CHECK sy-subrc = 0 AND
              <tif_value>-value IS NOT INITIAL and
              <tif_value>-value <> me->json_null.

        cache-transport_instructions =
          |{ cache-transport_instructions }| &&
          |{ COND #( WHEN cache-transport_instructions IS NOT INITIAL THEN ` `) }| &&
          |{ <tif_value>-value }|.
      ENDLOOP.

      LOOP AT me->defs->tcode_fields ASSIGNING FIELD-SYMBOL(<tcf>).
        APPEND LINES OF VALUE yif_addict_ticketing_system=>tcode_list(
                                FOR _entry IN results
                                WHERE ( parent = |/issues/1/fields/{ <tcf> }| and
                                        value <> me->json_null )
                                ( CONV #( _entry-value ) ) )
               TO cache-tcodes.
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


  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Initial object access
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    me->defs = ycl_ticksys_jira_def=>get_instance( ).

    me->subtask_parent_rng = VALUE #(
        ( sign   = ycl_addict_toolkit=>sign-include
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*/fields/subtasks/*' )
        ( sign   = ycl_addict_toolkit=>sign-exclude
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*/fields/subtasks/*/*' ) ).

    me->issue_link_parent_rng = VALUE #(
        ( sign   = ycl_addict_toolkit=>sign-include
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*/fields/issuelinks/*/inwardIssue' )
        ( sign   = ycl_addict_toolkit=>sign-include
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*/fields/issuelinks/*/outwardIssue' ) ).

    me->issue_key_parent_rng = VALUE #(
        ( sign   = ycl_addict_toolkit=>sign-include
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*' )
        ( sign   = ycl_addict_toolkit=>sign-exclude
          option = ycl_addict_toolkit=>option-cp
          low    = '/issues/*/*' ) ).

    me->status_parent_rng = VALUE #(
        ( sign   = ycl_addict_toolkit=>sign-include
          option = ycl_addict_toolkit=>option-cp
          low    = '/*' )
        ( sign   = ycl_addict_toolkit=>sign-exclude
          option = ycl_addict_toolkit=>option-cp
          low    = '/*/*' ) ).
  ENDMETHOD.


  METHOD http_get_jira_rest_api.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Call JIRA REST API via the given URL and return parsed results
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(http_client) = create_http_client( url ).
    http_client->request->set_method( if_http_request=>co_request_method_get ).

    http_client->send(
      EXCEPTIONS http_communication_failure = 1
                 http_invalid_state         = 2
                 http_processing_failed     = 3
                 http_invalid_timeout       = 4
                 OTHERS                     = 5 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
        EXPORTING
          textid   = ycx_ticksys_ticketing_system=>http_request_error
          ticsy_id = ycl_ticksys_jira=>ticsy_id.
    ENDIF.

    http_client->receive(
      EXCEPTIONS http_communication_failure = 1
                 http_invalid_state         = 2
                 http_processing_failed     = 3
                 OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
        EXPORTING
          textid   = ycx_ticksys_ticketing_system=>http_response_error
          ticsy_id = ycl_ticksys_jira=>ticsy_id.
    ENDIF.

    http_client->response->get_status( IMPORTING code = DATA(rc) ).
    DATA(response) = http_client->response->get_data( ).
    http_client->close( ).

    IF rc <> me->http_return-ok.
      RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
        EXPORTING
          textid           = ycx_ticksys_ticketing_system=>unexpected_http_status
          ticsy_id         = ycl_ticksys_jira=>ticsy_id
          http_status_code = rc.
    ENDIF.

    " Parse """""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(len) = 0.
    DATA(bin) = VALUE bin_list( ).

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = response
      IMPORTING
        output_length = len
      TABLES
        binary_tab    = bin.

    DATA(json_response) = CONV string( space ).

    CALL FUNCTION 'SCMS_BINARY_TO_STRING'
      EXPORTING
        input_length = len
      IMPORTING
        text_buffer  = json_response
      TABLES
        binary_tab   = bin
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
        EXPORTING
          textid   = ycx_ticksys_ticketing_system=>http_response_parse_error
          ticsy_id = ycl_ticksys_jira=>ticsy_id.
    ENDIF.

    DATA(parser) = NEW /ui5/cl_json_parser( ).
    parser->parse( json_response ).
    results = parser->m_entries.
  ENDMETHOD.
ENDCLASS.
