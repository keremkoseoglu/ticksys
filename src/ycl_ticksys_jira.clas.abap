CLASS ycl_ticksys_jira DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES yif_addict_ticketing_system.
    CONSTANTS ticsy_id TYPE yd_ticksys_ticsy_id VALUE 'JIRA'.
    CLASS-METHODS class_constructor.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF tcode_ticket_dict,
             tcode   TYPE tcode,
             tickets TYPE yif_addict_ticketing_system=>ticket_id_list,
           END OF tcode_ticket_dict,

           tcode_ticket_set TYPE HASHED TABLE OF tcode_ticket_dict
           WITH UNIQUE KEY primary_key COMPONENTS tcode.

    CONSTANTS: BEGIN OF status_code,
                 ok TYPE char3 VALUE '204',
               END OF status_code.

    CLASS-DATA defs TYPE REF TO ycl_ticksys_jira_def.
    CLASS-DATA reader TYPE REF TO ycl_ticksys_jira_reader.
    CLASS-DATA tcode_ticket_cache TYPE tcode_ticket_set.

    CLASS-METHODS get_ticket_url
      IMPORTING !ticket_id TYPE yd_addict_ticket_id
      RETURNING VALUE(url) TYPE string.

    METHODS get_assignee_fields_for_status
      IMPORTING !status_id    TYPE yd_addict_ticket_status_id
      RETURNING VALUE(fields) TYPE ycl_ticksys_jira_def=>jira_field_list.
ENDCLASS.



CLASS ycl_ticksys_jira IMPLEMENTATION.
  METHOD class_constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Called upon initial access
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        defs = ycl_ticksys_jira_def=>get_instance( ).
        reader = ycl_ticksys_jira_reader=>get_instance( ).
      CATCH cx_root INTO DATA(diaper).
        MESSAGE diaper TYPE ycl_simbal=>msgty-error.
    ENDTRY.
  ENDMETHOD.


  METHOD get_ticket_url.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns an URL for the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    url = |{ ycl_ticksys_jira=>defs->definitions-url }/browse/{ ticket_id }|.
  ENDMETHOD.


  METHOD get_assignee_fields_for_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns assignee fields for the given status
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    APPEND LINES OF VALUE ycl_ticksys_jira_def=>jira_field_list(
             FOR _jsaf IN me->defs->status_assignee_fields
             WHERE ( status_id = status_id )
             ( _jsaf-jira_field )
           ) TO fields.

    APPEND LINES OF VALUE ycl_ticksys_jira_def=>jira_field_list(
             FOR _jsaf IN me->defs->status_assignee_fields
             WHERE ( status_id = space )
             ( _jsaf-jira_field )
           ) TO fields.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~is_ticket_id_valid.
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


  METHOD yif_addict_ticketing_system~get_ticket_header.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the header of the ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        output = me->reader->get_jira_issue( ticket_id )-header.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_transport_instructions.
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
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_sub_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the sub-tickets of the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        children = me->reader->get_jira_issue( parent )-sub_tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_linked_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns tickets which are linked to the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        tickets = me->reader->get_jira_issue( ticket_id )-linked_tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_related_tcodes.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Gets the tcodes related to the given ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        tcodes = me->reader->get_jira_issue( ticket_id )-tcodes.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_tickets_related_to_tcodes.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of tickets related to the given TCodes
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        LOOP AT tcodes ASSIGNING FIELD-SYMBOL(<tcode>).
          ASSIGN me->tcode_ticket_cache[
                   KEY primary_key COMPONENTS
                   tcode = <tcode>
                 ] TO FIELD-SYMBOL(<cache>).

          IF sy-subrc <> 0.
            DATA(new_cache) = VALUE tcode_ticket_dict( tcode = <tcode> ).

            LOOP AT me->defs->tcode_fields ASSIGNING FIELD-SYMBOL(<tcode_field>).
              DATA(jql_field) = <tcode_field>.

              IF jql_field CS 'customfield_'.
                DATA(split1) = ||.
                DATA(split2) = ||.
                SPLIT jql_field AT '_' INTO split1 split2.
                jql_field = |cf[{ split2 }]|.
              ENDIF.

              DATA(results) = me->reader->search_issues( |{ jql_field }={ <tcode> }| ).
            ENDLOOP.

            APPEND LINES OF VALUE yif_addict_ticketing_system=>ticket_id_list(
                     FOR GROUPS _grp OF _result IN results
                     WHERE ( parent IN me->reader->issue_key_parent_rng AND
                             name = 'key' )
                     GROUP BY _result-value
                     ( CONV #( _grp ) )
                   ) TO new_cache-tickets.

            INSERT new_cache INTO TABLE me->tcode_ticket_cache ASSIGNING <cache>.
          ENDIF.

          APPEND LINES OF <cache>-tickets TO tickets.
        ENDLOOP.

        SORT tickets.
        DELETE ADJACENT DUPLICATES FROM tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~get_earliest_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns the earliest status from the given status values
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK statuses IS NOT INITIAL.

    TRY.
        DATA(unique_statuses) = statuses.
        SORT unique_statuses.
        DELETE ADJACENT DUPLICATES FROM unique_statuses.

        DATA(earliest_status_id) = CONV yd_addict_ticket_status_id( space ).
        DATA(earliest_status_order) = CONV ytticksys_jisto-status_order( 32767 ).

        DATA(status_master) = me->reader->get_statuses( ).

        LOOP AT unique_statuses ASSIGNING FIELD-SYMBOL(<status>).
          IF earliest_status_id IS INITIAL.
            earliest_status_id = <status>.
            CONTINUE.
          ENDIF.

          ASSIGN status_master[ KEY primary_key COMPONENTS
                                status_id = <status>
                              ] TO FIELD-SYMBOL(<status_master>).

          IF sy-subrc <> 0.
            RAISE EXCEPTION TYPE ycx_ticksys_ticket_status
              EXPORTING
                textid    = ycx_ticksys_ticket_status=>invalid_status_id
                status_id = <status>.
          ENDIF.

          LOOP AT me->defs->status_orders ASSIGNING FIELD-SYMBOL(<status_order>).
            CHECK <status_master>-status_text CP <status_order>-status_text_pattern AND
                  <status_order>-status_order < earliest_status_order.

            earliest_status_id = <status>.
            earliest_status_order = <status_order>-status_order.
          ENDLOOP.
        ENDLOOP.

        earliest = VALUE #( status_id   = earliest_status_id
                            status_text = VALUE #( status_master[ KEY primary_key COMPONENTS
                                                                  status_id = <status>
                                                                ]-status_text OPTIONAL ) ).

      CATCH ycx_addict_ticketing_system INTO DATA(system_error).
        RAISE EXCEPTION system_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_addict_ticketing_system
          EXPORTING
            textid   = ycx_addict_ticketing_system=>ycx_addict_ticketing_system
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~set_ticket_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the status of the ticket
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        " Create HTTP client """"""""""""""""""""""""""""""""""""""""
        DATA(url) = |{ me->defs->definitions-url }/rest/api/2/issue/{ ticket_id }/transitions|.
        DATA(http_client) = me->reader->create_http_client( url ).

        " Create body """""""""""""""""""""""""""""""""""""""""""""""
        DATA(current_status) = me->reader->get_jira_issue(
            ticket_id    = ticket_id
            bypass_cache = abap_true )-header-status_id.

        TRY.
            DATA(transition) = REF #( me->defs->transitions[
                               KEY primary_key COMPONENTS
                               from_status = current_status
                               to_status   = status_id ] ).

          CATCH cx_sy_itab_line_not_found INTO DATA(itab_error).
            RAISE EXCEPTION TYPE ycx_addict_table_content
              EXPORTING
                textid   = ycx_addict_table_content=>no_entry_for_objectid
                previous = itab_error
                tabname  = ycl_ticksys_jira_def=>table-jira_transitions
                objectid = |{ current_status }-{ status_id }|.
        ENDTRY.

        DATA(body) = |\{"transition":\{"id":"{ transition->transition_id }"\}\}|.
        DATA(rest_client) = NEW cl_rest_http_client( http_client ).

        DATA(request) = rest_client->if_rest_client~create_request_entity( ).
        request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
        request->set_string_data( body ).

        rest_client->if_rest_resource~post( request ).

        DATA(response) = rest_client->if_rest_client~get_response_entity( ).
        DATA(http_code) = response->get_header_field( '~status_code' ).

        IF http_code <> status_code-ok.
          RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
            EXPORTING
              textid    = ycx_ticksys_ticketing_system=>status_update_error
              ticsy_id  = me->ticsy_id
              ticket_id = ticket_id
              status_id = status_id.
        ENDIF.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~set_ticket_assignee.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the ticket assignee
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        DATA(url) = |{ me->defs->definitions-url }/rest/api/2/issue/{ ticket_id }|.
        DATA(http_client) = me->reader->create_http_client( url ).

        DATA(body) = |\{"fields":\{"assignee":\{"name":"{ assignee }"\}\}\}|.
        DATA(rest_client) = NEW cl_rest_http_client( http_client ).

        DATA(request) = rest_client->if_rest_client~create_request_entity( ).
        request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
        request->set_string_data( body ).

        rest_client->if_rest_resource~put( request ).

        DATA(response) = rest_client->if_rest_client~get_response_entity( ).
        DATA(http_code) = response->get_header_field( '~status_code' ).

        IF http_code <> me->status_code-ok.
          RAISE EXCEPTION TYPE ycx_ticksys_assignee_update
            EXPORTING
              ticket_id = ticket_id.
        ENDIF.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~set_ticket_assignee_for_status.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Sets the ticket assignee which corresponds to the provided status
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        DATA(ticket) = me->reader->get_jira_issue( ticket_id ).
        DATA(field_candidates) = get_assignee_fields_for_status( status_id ).

        LOOP AT field_candidates ASSIGNING FIELD-SYMBOL(<field>).
          ASSIGN ticket-custom_fields[
                   KEY primary_key COMPONENTS
                   jira_field = <field>
                 ] TO FIELD-SYMBOL(<custom_field>).

          CHECK sy-subrc = 0 AND <custom_field>-value IS NOT INITIAL.

          yif_addict_ticketing_system~set_ticket_assignee(
              ticket_id = ticket_id
              assignee  = <custom_field>-value ).

          RETURN.
        ENDLOOP.

        RAISE EXCEPTION TYPE ycx_ticksys_assignee_update
          EXPORTING
            textid    = ycx_ticksys_assignee_update=>new_assignee_not_found
            ticket_id = ticket_id.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_ticksys_ticketing_system
          EXPORTING
            previous = diaper.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_addict_ticketing_system~display_ticket.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Displays ticket in browser
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA url TYPE text100.

    CHECK ticket_id IS NOT INITIAL.
    url = get_ticket_url( ticket_id ).

    CALL FUNCTION 'CALL_BROWSER'
      EXPORTING
        url                    = url
      EXCEPTIONS
        frontend_not_supported = 1
        frontend_error         = 2
        prog_not_found         = 3
        no_batch               = 4
        unspecified_error      = 5
        OTHERS                 = 6 ##FM_SUBRC_OK.
  ENDMETHOD.
ENDCLASS.
