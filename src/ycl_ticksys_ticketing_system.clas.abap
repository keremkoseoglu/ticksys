CLASS ycl_ticksys_ticketing_system DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES: BEGIN OF key_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
           END OF key_dict.

    DATA def TYPE ytticksys_ticsy READ-ONLY.
    DATA implementation TYPE REF TO yif_addict_ticketing_system READ-ONLY.

    CLASS-METHODS get_instance
      IMPORTING !key       TYPE key_dict
      RETURNING VALUE(obj) TYPE REF TO ycl_ticksys_ticketing_system
      RAISING   ycx_addict_table_content.

    METHODS create_log
      RETURNING VALUE(log) TYPE REF TO ycl_simbal
      RAISING   ycx_addict_table_content.

  PROTECTED SECTION.
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
      RAISING   ycx_addict_table_content.
ENDCLASS.



CLASS ycl_ticksys_ticketing_system IMPLEMENTATION.
  METHOD get_instance.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Multiton factory
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    ASSIGN multitons[ KEY primary_key COMPONENTS key = key
                    ] TO FIELD-SYMBOL(<multiton>).
    IF sy-subrc <> 0.
      DATA(multiton) = VALUE multiton_dict( key = key ).

      TRY.
          multiton-obj = NEW #( multiton-key ).
        CATCH ycx_addict_table_content INTO multiton-cx ##NO_HANDLER.
      ENDTRY.

      INSERT multiton INTO TABLE multitons ASSIGNING <multiton>.
    ENDIF.

    IF <multiton>-cx IS NOT INITIAL.
      RAISE EXCEPTION <multiton>-cx.
    ENDIF.

    obj = <multiton>-obj.
  ENDMETHOD.


  METHOD create_log.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates & returns a new log object
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->def-bal_object IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = me->table-def
          objectid  = CONV #( me->def-ticsy_id )
          fieldname = me->field-bal_object.
    ENDIF.

    IF me->def-bal_subobject IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = me->table-def
          objectid  = CONV #( me->def-ticsy_id )
          fieldname = me->field-bal_subobject.
    ENDIF.

    TRY.
        log = NEW ycl_simbal( object    = me->def-bal_object
                              subobject = me->def-bal_subobject ).

      CATCH cx_root INTO DATA(simbal_error).
        RAISE EXCEPTION TYPE ycx_addict_table_content
          EXPORTING
            textid   = ycx_addict_table_content=>invalid_entry
            previous = simbal_error
            tabname  = me->table-def
            objectid = CONV #( me->def-ticsy_id ).
    ENDTRY.
  ENDMETHOD.


  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Called on object creation
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA obj TYPE REF TO object.

    SELECT SINGLE * FROM ytticksys_ticsy
           WHERE ticsy_id = @key-ticsy_id
           INTO CORRESPONDING FIELDS OF @me->def.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid   = ycx_addict_table_content=>no_entry_for_objectid
          tabname  = table-def
          objectid = |{ key-ticsy_id }|.
    ENDIF.

    IF me->def-ticsy_imp_class IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid   = ycx_addict_table_content=>invalid_entry
          tabname  = table-def
          objectid = |{ key-ticsy_id }|.
    ENDIF.

    TRY.
        CREATE OBJECT obj TYPE (me->def-ticsy_imp_class).
        me->implementation = CAST #( obj ).

      CATCH cx_root INTO DATA(implementation_error).
        RAISE EXCEPTION TYPE ycx_addict_table_content
          EXPORTING
            textid   = ycx_addict_table_content=>invalid_entry
            tabname  = table-def
            objectid = |{ key-ticsy_id }|.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
