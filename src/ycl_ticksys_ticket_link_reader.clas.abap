CLASS ycl_ticksys_ticket_link_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES: BEGIN OF input_dict,
             ticsy_id          TYPE yd_addict_ticsy_id,
             tickets           TYPE yif_addict_ticketing_system=>ticket_id_list,
             find_links        TYPE abap_bool,
             find_parent_child TYPE abap_bool,
             link_self         TYPE abap_bool,
             max_link_level    TYPE i,
           END OF input_dict.

    TYPES: BEGIN OF nested_dict,
             master TYPE yd_addict_ticket_id,
             linked TYPE yif_addict_ticketing_system=>ticket_id_list,
           END OF nested_dict,

           nested_set TYPE HASHED TABLE OF nested_dict
           WITH UNIQUE KEY primary_key COMPONENTS master.

    CLASS-METHODS execute
      IMPORTING !input  TYPE input_dict
      EXPORTING !flat   TYPE yif_addict_ticketing_system=>ticket_id_list
                !nested TYPE nested_set
      RAISING   ycx_addict_class_method.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF cache_dict,
             ticket_id      TYPE yd_addict_ticket_id,
             max_link_level TYPE i,
             linked         TYPE yif_addict_ticketing_system=>ticket_id_list,
           END OF cache_dict,

           cache_set TYPE HASHED TABLE OF cache_dict
           WITH UNIQUE KEY primary_key COMPONENTS ticket_id max_link_level.

    CONSTANTS: BEGIN OF field,
                 ticsy_id TYPE fieldname VALUE 'TICSY_ID',
               END OF field.

    CONSTANTS: BEGIN OF method,
                 constructor   TYPE seocpdname VALUE 'CONSTRUCTOR',
                 welcome_input TYPE seocpdname VALUE 'WELCOME_INPUT',
               END OF method.

    CLASS-DATA cache TYPE cache_set.

    DATA input TYPE input_dict.
    DATA flat TYPE yif_addict_ticketing_system=>ticket_id_list.
    DATA nested TYPE nested_set.

    DATA ticketing_sys TYPE REF TO ycl_ticksys_ticketing_system.
    DATA ticketing_imp TYPE REF TO yif_addict_ticketing_system.

    METHODS constructor
      IMPORTING !input TYPE input_dict
      RAISING   ycx_addict_class_method.

    METHODS welcome_input
      RAISING ycx_addict_method_parameter
              ycx_addict_table_content.

    METHODS read_tickets RAISING ycx_addict_ticketing_system.

    METHODS find_nested_links
      IMPORTING !yin        TYPE yd_addict_ticket_id
      CHANGING  !links      TYPE yif_addict_ticketing_system=>ticket_id_list
                !link_level TYPE i
      RAISING   ycx_addict_ticketing_system.

    METHODS append_link
      IMPORTING !yin        TYPE yd_addict_ticket_id
                !yang       TYPE yd_addict_ticket_id
      CHANGING  !links      TYPE yif_addict_ticketing_system=>ticket_id_list
                !link_level TYPE i
      RAISING   ycx_addict_ticketing_system.

    METHODS link_self.
    METHODS build_flat.
ENDCLASS.



CLASS ycl_ticksys_ticket_link_reader IMPLEMENTATION.
  METHOD execute.
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " End point
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CLEAR: flat, nested.
    DATA(reader) = NEW ycl_ticksys_ticket_link_reader( input ).

    flat    = reader->flat.
    nested  = reader->nested.
  ENDMETHOD.


  METHOD constructor.
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Start of execution
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        me->input = input.
        welcome_input( ).
        read_tickets( ).
        link_self( ).
        build_flat( ).

      CATCH ycx_addict_class_method INTO DATA(method_error).
        RAISE EXCEPTION method_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION TYPE ycx_addict_class_method
          EXPORTING
            textid   = ycx_addict_class_method=>unexpected_error
            previous = diaper
            class    = CONV #( ycl_addict_class=>get_class_name( me ) )
            method   = me->method-constructor.
    ENDTRY.
  ENDMETHOD.


  METHOD welcome_input.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Process and cleanse input values
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DELETE me->input-tickets WHERE table_line IS INITIAL.
    SORT me->input-tickets.
    DELETE ADJACENT DUPLICATES FROM me->input-tickets.

    IF me->input-ticsy_id IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_method_parameter
        EXPORTING
          textid      = ycx_addict_method_parameter=>param_value_initial
          class_name  = CONV #( ycl_addict_class=>get_class_name( me ) )
          method_name = me->method-welcome_input
          param_name  = CONV #( me->field-ticsy_id ).
    ENDIF.

    me->ticketing_sys = ycl_ticksys_ticketing_system=>get_instance( CORRESPONDING #( me->input ) ).
    me->ticketing_imp = ticketing_sys->implementation.
  ENDMETHOD.


  METHOD read_tickets.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads tickets to build link list
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT me->input-tickets ASSIGNING FIELD-SYMBOL(<ticket_id>).
      ASSIGN me->cache[ KEY primary_key COMPONENTS
                        ticket_id      = <ticket_id>
                        max_link_level = me->input-max_link_level
                      ] TO FIELD-SYMBOL(<cache>).

      IF sy-subrc <> 0.
        DATA(new_cache) = VALUE cache_dict(
            ticket_id      = <ticket_id>
            max_link_level = me->input-max_link_level ).

        DATA(link_level) = 0.

        find_nested_links(
          EXPORTING yin        = <ticket_id>
          CHANGING  links      = new_cache-linked
                    link_level = link_level  ).

        SORT new_cache-linked.
        INSERT new_cache INTO TABLE me->cache ASSIGNING <cache>.
      ENDIF.

      INSERT VALUE #( master = <ticket_id>
                      linked = <cache>-linked
                    ) INTO TABLE me->nested.
    ENDLOOP.
  ENDMETHOD.


  METHOD find_nested_links.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Recursively finds ticket links
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    link_level = link_level + 1.

    " Linked tickets """"""""""""""""""""""""""""""""""""""""""""""""
    IF me->input-find_links = abap_true AND
       me->input-max_link_level IS NOT INITIAL AND
       me->input-max_link_level >= link_level.

      DATA(ticket_links) = me->ticketing_imp->get_linked_tickets( yin ).

      LOOP AT ticket_links ASSIGNING FIELD-SYMBOL(<link>).
        append_link( EXPORTING yin        = yin
                               yang       = <link>
                     CHANGING  links      = links
                               link_level = link_level ).
      ENDLOOP.
    ENDIF.

    " Parent - child relations """"""""""""""""""""""""""""""""""""""
    IF me->input-find_parent_child = abap_true.
      data(ticket) = me->ticketing_imp->get_ticket_header( yin ).

        append_link( EXPORTING yin        = yin
                               yang       = ticket-parent_ticket_id
                     CHANGING  links      = links
                               link_level = link_level ).

      data(sub_tickets) = me->ticketing_imp->get_sub_tickets( yin ).

      loop at sub_tickets assigning field-symbol(<sub_ticket>).
        append_link( EXPORTING yin        = yin
                               yang       = <sub_ticket>
                     CHANGING  links      = links
                               link_level = link_level ).
      ENDLOOP.
    ENDIF.

    " Closure """""""""""""""""""""""""""""""""""""""""""""""""""""""
    link_level = link_level - 1.
  ENDMETHOD.


  METHOD append_link.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Appends the given link & recursively keeps seeking
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF yang IS INITIAL OR
       yang = yin OR
       line_exists( links[ table_line = yang ] ).
      RETURN.
    ENDIF.

    APPEND yang TO links.

    find_nested_links(
      EXPORTING yin        = yang
      CHANGING  links      = links
                link_level = link_level ).
  ENDMETHOD.


  METHOD link_self.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Put the tickets themselves into the list
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    CHECK me->input-link_self = abap_true.

    LOOP AT me->nested ASSIGNING FIELD-SYMBOL(<nest>).
      CHECK NOT line_exists( <nest>-linked[ table_line = <nest>-master ] ).
      APPEND <nest>-master TO <nest>-linked.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_flat.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Builds the flat list
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT me->nested ASSIGNING FIELD-SYMBOL(<nest>).
      APPEND LINES OF <nest>-linked TO me->flat.
    ENDLOOP.

    SORT me->flat.
    DELETE ADJACENT DUPLICATES FROM me->flat.
  ENDMETHOD.
ENDCLASS.
