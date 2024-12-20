CLASS ycl_ticksys_ticketing_system DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES: BEGIN OF key_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
           END OF key_dict.

    DATA def            TYPE ytticksys_ticsy                     READ-ONLY.
    DATA implementation TYPE REF TO yif_ticksys_ticketing_system READ-ONLY.

    CLASS-METHODS format_ticket_id_input
      CHANGING ticket_ids TYPE yif_ticksys_ticketing_system=>ticket_id_list.

    CLASS-METHODS get_instance
      IMPORTING !key       TYPE key_dict
      RETURNING VALUE(obj) TYPE REF TO ycl_ticksys_ticketing_system
      RAISING   ycx_addict_table_content.

    METHODS create_log
      RETURNING VALUE(log) TYPE REF TO ycl_simbal
      RAISING   ycx_addict_table_content.

  PRIVATE SECTION.
    TYPES: BEGIN OF multiton_dict,
             key TYPE key_dict,
             obj TYPE REF TO ycl_ticksys_ticketing_system,
             cx  TYPE REF TO ycx_addict_table_content,
           END OF multiton_dict,

           multiton_set TYPE HASHED TABLE OF multiton_dict
                        WITH UNIQUE KEY primary_key COMPONENTS key.

    CONSTANTS: BEGIN OF field,
                 bal_object    TYPE fieldname VALUE 'BAL_OBJECT',
                 bal_subobject TYPE fieldname VALUE 'BAL_SUBOBJECT',
               END OF field.

    CONSTANTS: BEGIN OF table,
                 def TYPE tabname VALUE 'YTTICKSYS_TICSY',
               END OF table.

    CLASS-DATA multitons TYPE multiton_set.

    METHODS constructor
      IMPORTING !key TYPE key_dict
                hub  TYPE REF TO yif_ticksys_ticket_sys_hub
      RAISING   ycx_addict_table_content.
ENDCLASS.


CLASS ycl_ticksys_ticketing_system IMPLEMENTATION.
  METHOD format_ticket_id_input.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " String-format ticket ID's
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT ticket_ids ASSIGNING FIELD-SYMBOL(<ticket_id>).
      CONDENSE <ticket_id>.
    ENDLOOP.
  ENDMETHOD.

  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Called on object creation
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA obj TYPE REF TO object.

    DATA(ticketing_systems) = hub->get_all_ticketing_systems( ).

    TRY.
        me->def = ticketing_systems[ KEY primary_key COMPONENTS ticsy_id = key-ticsy_id ].
      CATCH cx_sy_itab_line_not_found INTO DATA(itab_error).
        RAISE EXCEPTION NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>no_entry_for_objectid
                                                      previous = itab_error
                                                      tabname  = table-def
                                                      objectid = |{ key-ticsy_id }| ).
    ENDTRY.

    IF me->def-ticsy_imp_class IS INITIAL.
      RAISE EXCEPTION NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>invalid_entry
                                                    tabname  = table-def
                                                    objectid = |{ key-ticsy_id }| ).
    ENDIF.

    TRY.
        CREATE OBJECT obj TYPE (me->def-ticsy_imp_class)
          EXPORTING ticsy_id = key-ticsy_id.

        me->implementation = CAST #( obj ).

      CATCH cx_root INTO DATA(implementation_error).
        RAISE EXCEPTION NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>invalid_entry
                                                      tabname  = table-def
                                                      objectid = |{ key-ticsy_id }|
                                                      previous = implementation_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD create_log.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates & returns a new log object
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->def-bal_object IS INITIAL.
      RAISE EXCEPTION NEW ycx_addict_table_content( textid    = ycx_addict_table_content=>entry_field_empty
                                                    tabname   = me->table-def
                                                    objectid  = CONV #( me->def-ticsy_id )
                                                    fieldname = me->field-bal_object ).
    ENDIF.

    IF me->def-bal_subobject IS INITIAL.
      RAISE EXCEPTION NEW ycx_addict_table_content( textid    = ycx_addict_table_content=>entry_field_empty
                                                    tabname   = me->table-def
                                                    objectid  = CONV #( me->def-ticsy_id )
                                                    fieldname = me->field-bal_subobject ).
    ENDIF.

    TRY.
        log = NEW ycl_simbal( object    = me->def-bal_object
                              subobject = me->def-bal_subobject ).

      CATCH cx_root INTO DATA(simbal_error).
        RAISE EXCEPTION NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>invalid_entry
                                                      previous = simbal_error
                                                      tabname  = me->table-def
                                                      objectid = CONV #( me->def-ticsy_id ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Multiton factory
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    ASSIGN multitons[ KEY primary_key COMPONENTS key = key ]
           TO FIELD-SYMBOL(<multiton>).
    IF sy-subrc <> 0.
      DATA(multiton) = VALUE multiton_dict( key = key ).

      TRY.
          multiton-obj = NEW #( key = multiton-key
                                hub = CAST #( ycl_ticksys_ticket_sys_hub=>get_instance( ) ) ).
        CATCH ycx_addict_table_content INTO multiton-cx ##NO_HANDLER.
      ENDTRY.

      INSERT multiton INTO TABLE multitons ASSIGNING <multiton>.
    ENDIF.

    IF <multiton>-cx IS NOT INITIAL.
      RAISE EXCEPTION <multiton>-cx.
    ENDIF.

    obj = <multiton>-obj.
  ENDMETHOD.
ENDCLASS.
