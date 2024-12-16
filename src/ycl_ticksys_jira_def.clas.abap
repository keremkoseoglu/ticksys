CLASS ycl_ticksys_jira_def DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES jista_list        TYPE STANDARD TABLE OF ytticksys_jista WITH EMPTY KEY.
    TYPES jira_field_list   TYPE STANDARD TABLE OF yd_ticksys_jira_field WITH EMPTY KEY.
    TYPES status_order_list TYPE STANDARD TABLE OF ytticksys_jisto WITH EMPTY KEY.

    TYPES transition_set    TYPE HASHED TABLE OF ytticksys_jitra
          WITH UNIQUE KEY primary_key COMPONENTS from_status to_status.

    CONSTANTS: BEGIN OF field,
                 url      TYPE fieldname VALUE 'URL',
                 username TYPE fieldname VALUE 'USERNAME',
                 password TYPE fieldname VALUE 'PASSWORD',
               END OF field.

    CONSTANTS: BEGIN OF table,
                 jira_def         TYPE tabname VALUE 'YTTICKSYS_JIDEF',
                 jira_transitions TYPE tabname VALUE 'YTTICKSYS_JITRA',
                 status_order     TYPE tabname VALUE 'YTTICKSYS_JISTO',
               END OF table.

    DATA: definitions                  TYPE ytticksys_jidef   READ-ONLY,
          transitions                  TYPE transition_set    READ-ONLY,
          status_assignee_fields       TYPE jista_list        READ-ONLY,
          status_orders                TYPE status_order_list READ-ONLY,
          transport_instruction_fields TYPE jira_field_list   READ-ONLY,
          tcode_fields                 TYPE jira_field_list   READ-ONLY,
          main_module_fields           TYPE jira_field_list   READ-ONLY.

    CLASS-METHODS get_instance
      IMPORTING ticsy_id      TYPE yd_ticksys_ticsy_id
      RETURNING VALUE(result) TYPE REF TO ycl_ticksys_jira_def
      RAISING   ycx_addict_table_content.

  PRIVATE SECTION.
    TYPES: BEGIN OF multiton_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
             obj      TYPE REF TO ycl_ticksys_jira_def,
           END OF multiton_dict,

           multiton_set TYPE HASHED TABLE OF multiton_dict WITH UNIQUE KEY primary_key COMPONENTS ticsy_id.

    CLASS-DATA multitons TYPE multiton_set.

    METHODS constructor
      IMPORTING ticsy_id TYPE yd_ticksys_ticsy_id
      RAISING   ycx_addict_table_content.
ENDCLASS.


CLASS ycl_ticksys_jira_def IMPLEMENTATION.
  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Object creation
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    SELECT SINGLE * FROM ytticksys_jidef
           WHERE sysid    = @sy-sysid
             AND ticsy_id = @ticsy_id
           INTO CORRESPONDING FIELDS OF @me->definitions.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_addict_table_content( textid   = ycx_addict_table_content=>no_entry_for_objectid
                                                    tabname  = ycl_ticksys_jira_def=>table-jira_def
                                                    objectid = |{ sy-sysid }-{ ticsy_id }| ).
    ENDIF.

    IF me->definitions-url IS INITIAL.
      RAISE EXCEPTION NEW ycx_addict_table_content( textid    = ycx_addict_table_content=>entry_field_empty
                                                    tabname   = ycl_ticksys_jira_def=>table-jira_def
                                                    objectid  = |{ sy-sysid }-{ ticsy_id }|
                                                    fieldname = field-url ).
    ENDIF.

    SELECT * FROM ytticksys_jitra
           WHERE ticsy_id = @ticsy_id
           INTO TABLE @me->transitions.

    SELECT * FROM ytticksys_jista
           WHERE ticsy_id = @ticsy_id
           ORDER BY status_id, priority
           INTO TABLE @me->status_assignee_fields.

    SELECT jira_field FROM ytticksys_jitif "#EC CI_NOFIELD
           WHERE ticsy_id    = @ticsy_id
             AND jira_field <> @space
           INTO TABLE @me->transport_instruction_fields.

    SELECT jira_field FROM ytticksys_jitcf "#EC CI_NOFIELD
           WHERE ticsy_id    = @ticsy_id
             AND jira_field <> @space
           INTO TABLE @me->tcode_fields.

    SELECT jira_field FROM ytticksys_jimmf "#EC CI_NOFIELD
           WHERE ticsy_id    = @ticsy_id
             AND jira_field <> @space
           INTO TABLE @me->main_module_fields.

    SELECT * FROM ytticksys_jisto
           WHERE ticsy_id = @ticsy_id
           INTO TABLE @me->status_orders.
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
ENDCLASS.
