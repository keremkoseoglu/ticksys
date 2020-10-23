CLASS ycl_ticksys_jira DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES yif_addict_ticketing_system.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF bin_dict,
             line TYPE x LENGTH 255,
           END OF bin_dict,

           bin_list TYPE STANDARD TABLE OF bin_dict WITH EMPTY KEY.

    constants ticsy_id type yd_ticksys_ticsy_id value 'JIRA'.

    CONSTANTS: BEGIN OF http_return,
                 ok TYPE i VALUE 200,
               END OF http_return.

    CONSTANTS: BEGIN OF table,
                 jira_def TYPE tabname VALUE 'YTTICKSYS_JIDEF',
               END OF table.

    CONSTANTS: BEGIN OF field,
                 search_rfc_dest TYPE fieldname VALUE 'SEARCH_RFC_DEST',
               END OF field.

    DATA jira_definitions TYPE ytticksys_jidef.

    METHODS lazy_read_jira_definitions
      RAISING ycx_addict_table_content.

    METHODS read_jira_issue
      IMPORTING !ticket_id   TYPE yd_addict_ticket_id
      RETURNING VALUE(output) TYPE string
      RAISING   ycx_ticksys_ticketing_system
                ycx_addict_table_content.
ENDCLASS.



CLASS ycl_ticksys_jira IMPLEMENTATION.
  METHOD lazy_read_jira_definitions.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads & caches Jira based definitions
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK me->jira_definitions IS INITIAL.

    SELECT SINGLE * FROM ytticksys_jidef
           WHERE sysid = @sy-sysid
           INTO CORRESPONDING FIELDS OF @me->jira_definitions.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid   = ycx_addict_table_content=>no_entry_for_objectid
          tabname  = me->table-jira_def
          objectid = CONV #( sy-sysid ).
    ENDIF.

    IF me->jira_definitions-search_rfc_dest IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = me->table-jira_def
          fieldname = me->field-search_rfc_dest
          objectid  = CONV #( sy-sysid ).
    ENDIF.
  ENDMETHOD.


  METHOD read_jira_issue.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads the given Jira issue from the server
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    lazy_read_jira_definitions( ).

    cl_http_client=>create_by_destination(
      EXPORTING destination = me->jira_definitions-search_rfc_dest
      IMPORTING client      = DATA(http_client) ).

    http_client->request->set_method( if_http_request=>co_request_method_get ).

    http_client->request->set_form_field(
        name  = 'jql'
        value = |issuekey={ ticket_id }| ).

    http_client->request->set_form_field(
        name  = 'expand'
        value = 'names,renderedFields,schema,transitions,operations,editmeta,changelog' ).

    http_client->request->set_form_field(
        name  = 'maxResults'
        value = '1' ).

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
          textid   = ycx_ticksys_ticketing_system=>http_responded_with_error
          ticsy_id = ycl_ticksys_jira=>ticsy_id.
    ENDIF.

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

    output = json_response.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~is_ticket_id_valid.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Checks if the ticket exists in the system
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        lazy_read_jira_definitions( ).

        TRY.
            read_jira_issue( ticket_id ).
            output = abap_true.
          CATCH cx_root.
            output = abap_false.
        ENDTRY.

      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
