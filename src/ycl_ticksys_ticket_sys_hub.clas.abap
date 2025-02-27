CLASS ycl_ticksys_ticket_sys_hub DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_ticksys_ticket_sys_hub.

    CLASS-METHODS get_instance RETURNING VALUE(result) TYPE REF TO ycl_ticksys_ticket_sys_hub.

  PRIVATE SECTION.
    TYPES: BEGIN OF ticket_cache_dict,
             ticket_id      TYPE yd_ticksys_ticket_id,

             ticsy_id_read  TYPE abap_bool,
             ticsy_id       TYPE yd_ticksys_ticsy_id,
             ticsy_id_error TYPE REF TO ycx_ticksys_ticket,

             header_read    TYPE abap_bool,
             header         TYPE ysticksys_ticket_header,
             header_error   TYPE REF TO ycx_ticksys_ticket,
           END OF ticket_cache_dict,

           ticket_cache_set TYPE HASHED TABLE OF ticket_cache_dict WITH UNIQUE KEY primary_key COMPONENTS ticket_id.

    CLASS-DATA singleton TYPE REF TO ycl_ticksys_ticket_sys_hub.

    DATA: ticket_cache           TYPE ticket_cache_set,
          ticketing_systems      TYPE yif_ticksys_ticket_sys_hub=>ticketing_system_set,
          ticketing_systems_read TYPE abap_bool.

    METHODS get_or_init_ticket_in_cache
      IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
      RETURNING VALUE(result) TYPE REF TO ticket_cache_dict.

    METHODS set_ticket_system_id
      IMPORTING ticsy_id     TYPE yd_ticksys_ticsy_id
                ticket_cache TYPE REF TO ticket_cache_dict.

    METHODS get_ticketing_systems_lazy RETURNING VALUE(result) TYPE REF TO yif_ticksys_ticket_sys_hub=>ticketing_system_set.
ENDCLASS.


CLASS ycl_ticksys_ticket_sys_hub IMPLEMENTATION.
  METHOD get_instance.
    IF singleton IS INITIAL.
      singleton = NEW #( ).
    ENDIF.

    result = singleton.
  ENDMETHOD.

  METHOD get_or_init_ticket_in_cache.
    TRY.
        result = REF #( me->ticket_cache[ KEY primary_key
                                          ticket_id = ticket_id ] ).
      CATCH cx_sy_itab_line_not_found.
        INSERT VALUE #( ticket_id = ticket_id ) INTO TABLE me->ticket_cache REFERENCE INTO result.
    ENDTRY.
  ENDMETHOD.

  METHOD set_ticket_system_id.
    ASSERT ticsy_id IS NOT INITIAL.
    ticket_cache->ticsy_id      = ticsy_id.
    ticket_cache->ticsy_id_read = abap_true.
    CLEAR ticket_cache->ticsy_id_error.
  ENDMETHOD.

  METHOD get_ticketing_systems_lazy.
    result = REF #( me->ticketing_systems ).
    CHECK me->ticketing_systems_read = abap_false.

    SELECT * FROM ytticksys_ticsy "#EC CI_NOFIELD
           WHERE ticsy_id <> @space
           INTO CORRESPONDING FIELDS OF TABLE
           @result->*.

    me->ticketing_systems_read = abap_true.
  ENDMETHOD.

  METHOD yif_ticksys_ticket_sys_hub~get_first_system_with_ticket.
    DATA(ticket_cache) = get_or_init_ticket_in_cache( ticket_id ).

    IF ticket_cache->ticsy_id_read IS INITIAL.
      DO 1 TIMES.
        DATA(tick_systems_having_ticket) = yif_ticksys_ticket_sys_hub~get_systems_with_ticket( ticket_id ).

        IF tick_systems_having_ticket IS INITIAL.
          ticket_cache->ticsy_id_error = NEW #( textid    = ycx_ticksys_ticket=>ticket_not_found
                                                ticsy_id  = space
                                                ticket_id = ticket_id ).
          EXIT.
        ENDIF.

        LOOP AT tick_systems_having_ticket REFERENCE INTO DATA(tick_sys_def).
          set_ticket_system_id( ticsy_id     = tick_sys_def->ticsy_id
                                ticket_cache = ticket_cache ).
          EXIT. "#EC CI_NOORDER
        ENDLOOP.
      ENDDO.

      ticket_cache->ticsy_id_read = abap_true.
    ENDIF.

    IF ticket_cache->ticsy_id_error IS NOT INITIAL.
      RAISE EXCEPTION ticket_cache->ticsy_id_error.
    ENDIF.

    result = ticket_cache->ticsy_id.
  ENDMETHOD.

  METHOD yif_ticksys_ticket_sys_hub~read_ticket_header.
    CLEAR: ticket_header,
           ticket_ticsy_id.

    DATA(ticket_cache) = get_or_init_ticket_in_cache( ticket_id ).

    IF ticket_cache->header_read = abap_false.
      TRY.
          IF known_ticsy_id IS NOT INITIAL.
            DATA(ticsy_id) = known_ticsy_id.

            set_ticket_system_id( ticsy_id     = ticsy_id
                                  ticket_cache = ticket_cache ).

          ELSE.
            ticsy_id = yif_ticksys_ticket_sys_hub~get_first_system_with_ticket( ticket_id ).
          ENDIF.

          DATA(ticket_system)  = ycl_ticksys_ticketing_system=>get_instance( VALUE #( ticsy_id = ticsy_id ) ).
          ticket_cache->header = ticket_system->implementation->get_ticket_header( ticket_cache->ticket_id ).

        CATCH ycx_ticksys_ticket INTO ticket_cache->header_error ##NO_HANDLER.
        CATCH cx_root INTO DATA(diaper).
          ticket_cache->header_error = NEW #( textid   = ycx_ticksys_ticket=>ticket_not_found
                                              previous = diaper ).
      ENDTRY.

      ticket_cache->header_read = abap_true.
    ENDIF.

    IF ticket_cache->header_error IS NOT INITIAL.
      RAISE EXCEPTION ticket_cache->header_error.
    ENDIF.

    ticket_header   = ticket_cache->header.
    ticket_ticsy_id = ticket_cache->ticsy_id.
  ENDMETHOD.

  METHOD yif_ticksys_ticket_sys_hub~get_systems_with_ticket.
    DATA(ticketing_systems) = get_ticketing_systems_lazy( ).

    LOOP AT ticketing_systems->* REFERENCE INTO DATA(ts).
      TRY.
          DATA(ticket_sys) = ycl_ticksys_ticketing_system=>get_instance( VALUE #( ticsy_id = ts->ticsy_id ) ).
          CHECK ticket_sys->implementation->is_ticket_id_valid( ticket_id ).

        CATCH cx_root.
          CONTINUE.
      ENDTRY.

      INSERT ts->* INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD yif_ticksys_ticket_sys_hub~get_all_ticketing_systems.
    DATA(ticketing_systems) = get_ticketing_systems_lazy( ).
    result = ticketing_systems->*.
  ENDMETHOD.
ENDCLASS.
