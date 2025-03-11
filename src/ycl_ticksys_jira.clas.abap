CLASS ycl_ticksys_jira DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_ticksys_ticketing_system.

    METHODS constructor IMPORTING ticsy_id TYPE yd_ticksys_ticsy_id.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF status_code,
                 ok TYPE char3 VALUE '204',
               END OF status_code.

    DATA: defs   TYPE REF TO ycl_ticksys_jira_def,
          reader TYPE REF TO ycl_ticksys_jira_reader.

    METHODS get_ticket_url
      IMPORTING ticket_id  TYPE yd_ticksys_ticket_id
      RETURNING VALUE(url) TYPE string.

    METHODS get_assignee_fields_for_status
      IMPORTING status_id     TYPE yd_ticksys_ticket_status_id
      RETURNING VALUE(fields) TYPE ycl_ticksys_jira_def=>jira_field_list.

    METHODS get_status_change_transition
      IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
                status_id     TYPE yd_ticksys_ticket_status_id
      RETURNING VALUE(result) TYPE REF TO ytticksys_jitra
      RAISING   ycx_ticksys_ticketing_system
                ycx_ticksys_undefined_status_c.

    METHODS conv_sap_date_to_jira_date
      IMPORTING sap_date      TYPE dats
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ycl_ticksys_jira IMPLEMENTATION.
  METHOD constructor.
    TRY.
        me->defs   = ycl_ticksys_jira_def=>get_instance( ticsy_id ).
        me->reader = ycl_ticksys_jira_reader=>get_instance( ticsy_id ).
      CATCH cx_root INTO DATA(diaper).
        MESSAGE diaper TYPE ycl_simbal=>msgty-error.
    ENDTRY.
  ENDMETHOD.

  METHOD get_assignee_fields_for_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns assignee fields for the given status
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    APPEND LINES OF VALUE ycl_ticksys_jira_def=>jira_field_list( FOR _jsaf IN me->defs->status_assignee_fields
                                                                 WHERE ( status_id = status_id )
                                                                 ( _jsaf-jira_field ) )
           TO fields.

    APPEND LINES OF VALUE ycl_ticksys_jira_def=>jira_field_list( FOR _jsaf IN me->defs->status_assignee_fields
                                                                 WHERE ( status_id = space )
                                                                 ( _jsaf-jira_field ) )
           TO fields.
  ENDMETHOD.

  METHOD get_status_change_transition.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the transition needed for status change
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(current_status) = me->reader->get_jira_issue( ticket_id    = ticket_id
                                                       bypass_cache = abap_true
                           )-header-status_id.

    TRY.
        result = REF #( me->defs->transitions[
                                        KEY primary_key
                                        COMPONENTS from_status = current_status
                                                   to_status   = status_id ] ).

      CATCH cx_sy_itab_line_not_found INTO DATA(itab_error).
        DATA(table_content_error) =
          NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>no_entry_for_objectid
                                        previous = itab_error
                                        tabname  = ycl_ticksys_jira_def=>table-jira_transitions
                                        objectid = |{ current_status }-{ status_id }| ).

        RAISE EXCEPTION NEW ycx_ticksys_undefined_status_c(
                                textid    = ycx_ticksys_undefined_status_c=>ticket_cant_be_set
                                previous  = table_content_error
                                ticket_id = ticket_id
                                status_id = status_id ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_ticket_url.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns an URL for the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    url = |{ me->defs->definitions-url }/browse/{ ticket_id }|.
  ENDMETHOD.

  METHOD conv_sap_date_to_jira_date.
    result = |{ sap_date+0(4) }-{ sap_date+4(2) }-{ sap_date+6(2) }|.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~can_set_ticket_to_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Tells if the ticket can be set to the desired status
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        get_status_change_transition( ticket_id = ticket_id
                                      status_id = status_id ).
        result = abap_true.

      CATCH ycx_ticksys_undefined_status_c.
        result = abap_false.

      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~display_ticket.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Displays ticket in browser
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    DATA url TYPE text100.

    CHECK ticket_id IS NOT INITIAL.
    url = get_ticket_url( ticket_id ).

    CALL FUNCTION 'CALL_BROWSER'
      EXPORTING  url                    = url
      EXCEPTIONS frontend_not_supported = 1
                 frontend_error         = 2
                 prog_not_found         = 3
                 no_batch               = 4
                 unspecified_error      = 5
                 OTHERS                 = 6 ##FM_SUBRC_OK.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_earliest_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the earliest status from the given status values
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK statuses IS NOT INITIAL.

    TRY.
        IF me->defs->status_orders IS INITIAL.
          RAISE EXCEPTION NEW ycx_addict_table_content( textid  = ycx_addict_table_content=>table_empty
                                                        tabname = ycl_ticksys_jira_def=>table-status_order ).
        ENDIF.

        DATA(unique_statuses) = statuses.
        SORT unique_statuses.
        DELETE ADJACENT DUPLICATES FROM unique_statuses.

        DATA(earliest_status_id) = CONV yd_ticksys_ticket_status_id( space ).
        DATA(earliest_status_order) = CONV ytticksys_jisto-status_order( 32767 ).

        DATA(status_master) = me->reader->get_statuses( ).

        LOOP AT unique_statuses ASSIGNING FIELD-SYMBOL(<status>).
          IF earliest_status_id IS INITIAL.
            earliest_status_id = <status>.
            CONTINUE.
          ENDIF.

          ASSIGN status_master[ KEY primary_key COMPONENTS status_id = <status> ]
                 TO FIELD-SYMBOL(<status_master>).

          IF sy-subrc <> 0.
            RAISE EXCEPTION NEW ycx_ticksys_ticket_status( textid    = ycx_ticksys_ticket_status=>invalid_status_id
                                                           status_id = <status> ).
          ENDIF.

          LOOP AT me->defs->status_orders ASSIGNING FIELD-SYMBOL(<status_order>).
            CHECK     <status_master>-status_text CP <status_order>-status_text_pattern
                  AND <status_order>-status_order  < earliest_status_order.

            earliest_status_id = <status>.
            earliest_status_order = <status_order>-status_order.
          ENDLOOP.
        ENDLOOP.

        earliest = VALUE #( status_id   = earliest_status_id
                            status_text = VALUE #( status_master[ KEY primary_key COMPONENTS status_id = <status>
                                                   ]-status_text OPTIONAL ) ).

      CATCH ycx_ticksys_ticketing_system INTO DATA(system_error).
        RAISE EXCEPTION system_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                                textid   = ycx_ticksys_ticketing_system=>ycx_ticksys_ticketing_system
                                previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_linked_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns tickets which are linked to the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        tickets = me->reader->get_jira_issue( ticket_id )-linked_tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_related_tcodes.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Gets the tcodes related to the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        tcodes = me->reader->get_jira_issue( ticket_id )-tcodes.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_sub_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the sub-tickets of the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        children = me->reader->get_jira_issue( parent )-sub_tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_tickets_related_to_tcodes.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of tickets related to the given TCodes
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        tickets = ycl_ticksys_jira_gtrttc=>get_instance( me->defs->definitions-ticsy_id )->execute( tcodes ).

      CATCH ycx_ticksys_ticketing_system INTO DATA(system_error).
        RAISE EXCEPTION system_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_tickets_with_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the tickets having the passed statuses
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK statuses IS NOT INITIAL.

    TRY.
        DATA(status_csv) =
          REDUCE string( INIT _scsv TYPE string
                         FOR _status IN statuses
                         NEXT _scsv = |{ _scsv }| &&
                                     |{ COND #( WHEN _scsv IS NOT INITIAL THEN ', ' ) }| &&
                                     |{ _status }| ).

        DATA(jql) = |status in ({ status_csv })|.

        IF types IS NOT INITIAL.
          DATA(type_csv) =
            REDUCE string( INIT _tcsv TYPE string
                           FOR _type IN types
                           NEXT _tcsv = |{ _tcsv }| &&
                                       |{ COND #( WHEN _tcsv IS NOT INITIAL THEN ', ' ) }| &&
                                       |{ _type }| ).

          jql = |{ jql } and issuetype in ({ type_csv })|.
        ENDIF.

        DATA(issues) = me->reader->search_issues( jql ).
        DATA(issues_copy) = issues.

        LOOP AT issues ASSIGNING FIELD-SYMBOL(<issue>)
             WHERE     parent IN me->reader->issue_key_parent_rng "#EC CI_SORTSEQ
                   AND name    = 'key'.

          DATA(entry) =
            VALUE yif_ticksys_ticketing_system=>ticket_status_dict(
                      ticket_id = <issue>-value
                      status_id = VALUE #( issues_copy[ type    = <issue>-type
                                                        subtype = <issue>-subtype
                                                        parent  = |{ <issue>-parent }/fields/status|
                                                        name    = 'id'
                                           ]-value OPTIONAL ) ).

          APPEND entry TO tickets.
        ENDLOOP.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_modified_tickets.
    LOOP AT users REFERENCE INTO DATA(user).
      DATA(date_cursor) = begda.

      WHILE date_cursor <= endda.
        DATA(jira_date) = conv_sap_date_to_jira_date( date_cursor ).
        ##NO_TEXT
        DATA(jql)    = |issue in updatedBy("{ user->* }", "{ jira_date }")|.
        DATA(issues) = me->reader->search_issues( jql ).

        DATA(user_tickets_on_date) = VALUE yif_ticksys_ticketing_system=>ticket_id_list( FOR GROUPS _id OF _iss IN issues
                                                                                         WHERE (     parent IN me->reader->issue_key_parent_rng "#EC CI_SORTSEQ
                                                                                                 AND name    = 'key'
                                                                                                 AND value  IS NOT INITIAL )
                                                                                         GROUP BY _iss-value
                                                                                         ( CONV #( _id ) ) ).

        APPEND LINES OF user_tickets_on_date TO tickets.
        date_cursor = date_cursor + 1.
      ENDWHILE.
    ENDLOOP.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_ticket_header.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the header of the ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        output = me->reader->get_jira_issue( ticket_id )-header.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_transport_instructions.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns transport instructions from Jira
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        DATA(issue) = me->reader->get_jira_issue( ticket_id ).
        IF issue-transport_instructions IS NOT INITIAL.
          instructions = VALUE #( ( issue-transport_instructions ) ).
        ENDIF.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~is_ticket_id_valid.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Checks if the ticket exists in the system
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        me->reader->get_jira_issue( ticket_id ).
        output = abap_true.
      CATCH cx_root.
        output = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~set_ticket_assignee.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the ticket assignee
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        DATA(url)         = |{ me->defs->definitions-url }/rest/api/2/issue/{ ticket_id }|.
        DATA(http_client) = me->reader->create_http_client( url ).
        DATA(body)        = |\{"fields":\{"assignee":\{"{ me->defs->definitions-assignee_fld }":"{ assignee }"\}\}\}|.
        DATA(rest_client) = NEW cl_rest_http_client( http_client ).
        DATA(request)     = rest_client->if_rest_client~create_request_entity( ).

        request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
        request->set_string_data( body ).
        rest_client->if_rest_resource~put( request ).

        DATA(response)  = rest_client->if_rest_client~get_response_entity( ).
        DATA(http_code) = response->get_header_field( '~status_code' ).

        IF http_code <> me->status_code-ok.
          RAISE EXCEPTION NEW ycx_ticksys_assignee_update( ticket_id = ticket_id ).
        ENDIF.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~set_ticket_assignee_for_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the ticket assignee which corresponds to the provided status
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        DATA(ticket) = me->reader->get_jira_issue( ticket_id ).
        DATA(field_candidates) = get_assignee_fields_for_status( status_id ).

        LOOP AT field_candidates ASSIGNING FIELD-SYMBOL(<field>).
          ASSIGN ticket-custom_fields[ KEY primary_key COMPONENTS jira_field = <field> ]
                 TO FIELD-SYMBOL(<custom_field>).

          CHECK sy-subrc = 0 AND <custom_field>-value IS NOT INITIAL.

          yif_ticksys_ticketing_system~set_ticket_assignee( ticket_id = ticket_id
                                                            assignee  = <custom_field>-value ).

          RETURN.
        ENDLOOP.

        RAISE EXCEPTION NEW ycx_ticksys_assignee_update( textid    = ycx_ticksys_assignee_update=>new_assignee_not_found
                                                         ticket_id = ticket_id ).

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~set_ticket_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the status of the ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        " Create HTTP client """"""""""""""""""""""""""""""""""""""""
        DATA(url) = |{ me->defs->definitions-url }/rest/api/2/issue/{ ticket_id }/transitions|.
        DATA(http_client) = me->reader->create_http_client( url ).

        " Create body """""""""""""""""""""""""""""""""""""""""""""""
        DATA(transition) = get_status_change_transition( ticket_id = ticket_id
                                                         status_id = status_id ).

        DATA(body) = |\{"transition":\{"id":"{ transition->transition_id }"\}\}|.
        DATA(rest_client) = NEW cl_rest_http_client( http_client ).

        DATA(request) = rest_client->if_rest_client~create_request_entity( ).
        request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
        request->set_string_data( body ).

        rest_client->if_rest_resource~post( request ).

        DATA(response)  = rest_client->if_rest_client~get_response_entity( ).
        DATA(http_code) = response->get_header_field( '~status_code' ).

        IF http_code <> status_code-ok.
          RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                                  textid    = ycx_ticksys_ticketing_system=>status_update_error
                                  ticsy_id  = me->defs->definitions-ticsy_id
                                  ticket_id = ticket_id
                                  status_id = status_id ).
        ENDIF.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_ticksys_ticketing_system~get_ticsy_id.
    result = me->defs->definitions-ticsy_id.
  ENDMETHOD.
ENDCLASS.
