REPORT yp_ticksys_ticket_list.

TABLES ysaddict_ticket_header.
PARAMETERS p_ticsy TYPE ytticksys_ticsy-ticsy_id OBLIGATORY VALUE CHECK.
SELECT-OPTIONS s_ticket FOR ysaddict_ticket_header-ticket_id OBLIGATORY NO INTERVALS.


CLASS main DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS run.

  PRIVATE SECTION.
    TYPES ticket_header_list TYPE STANDARD TABLE OF ysaddict_ticket_header
          WITH KEY ticket_id.

    constants msgid type symsgid value 'YTICKSYS'.
    CONSTANTS cprog TYPE sycprog VALUE 'YP_TICKSYS_TICKET_LIST'.

    CONSTANTS: BEGIN OF table,
                 ticket_header TYPE tabname VALUE 'YSADDICT_TICKET_HEADER',
               END OF table.

    CLASS-DATA ticketing_system TYPE REF TO ycl_ticksys_ticketing_system.
    CLASS-DATA log TYPE REF TO ycl_simbal.
    CLASS-DATA ticket_headers TYPE ticket_header_list.

    CLASS-METHODS create_objects RAISING ycx_addict_table_content.
    CLASS-METHODS read_tickets.
    CLASS-METHODS display_msg RAISING ycx_simbal_log.
    CLASS-METHODS display_alv RAISING ycx_addict_alv.
ENDCLASS.


CLASS main IMPLEMENTATION.
  METHOD run.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Main entry point
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        create_objects( ).
        read_tickets( ).
        display_msg( ).
        display_alv( ).

      CATCH cx_root INTO DATA(diaper).
        ycl_simbal_gui=>display_cx_msg_popup( diaper ).
        LEAVE LIST-PROCESSING.
    ENDTRY.
  ENDMETHOD.


  METHOD create_objects.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates objects to be used
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    main=>ticketing_system = ycl_ticksys_ticketing_system=>get_instance( VALUE #( ticsy_id = p_ticsy ) ).
    main=>log = main=>ticketing_system->create_log( ).
  ENDMETHOD.


  METHOD read_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Read tickets from the source system
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT s_ticket ASSIGNING FIELD-SYMBOL(<ticket>).
      TRY.
          APPEND main=>ticketing_system->implementation->get_ticket_header( <ticket>-low )
                 TO main=>ticket_headers.

        CATCH cx_root INTO DATA(ticket_error).
          main=>log->add_t100_msg(
              msgid = main=>msgid
              msgno = '002'
              msgty = ycl_simbal=>msgty-error
              msgv1 = <ticket>-low ).

          main=>log->add_exception( ticket_error ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD display_msg.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Displays messages produced during execution
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK main=>log IS NOT INITIAL AND
          main=>log->get_message_count( ) IS NOT INITIAL.

    NEW ycl_simbal_gui( main=>log )->show_light_popup( ).
  ENDMETHOD.


  METHOD display_alv.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Display tickets via ALV
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    NEW ycl_addict_alv( REF #( main=>ticket_headers ) )->show_grid( ).
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  main=>run( ).
