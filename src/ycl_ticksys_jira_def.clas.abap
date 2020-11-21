CLASS ycl_ticksys_jira_def DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES jista_list TYPE STANDARD TABLE OF ytticksys_jista WITH EMPTY KEY.
    TYPES jira_field_list TYPE STANDARD TABLE OF yd_ticksys_jira_field WITH EMPTY KEY.
    TYPES status_order_list TYPE STANDARD TABLE OF ytticksys_jisto WITH EMPTY KEY.

    TYPES transition_set TYPE HASHED TABLE OF ytticksys_jitra
          WITH UNIQUE KEY primary_key COMPONENTS from_status to_status.

    CONSTANTS: BEGIN OF field,
                 url      TYPE fieldname VALUE 'URL',
                 username TYPE fieldname VALUE 'USERNAME',
                 password TYPE fieldname VALUE 'PASSWORD',
               END OF field.

    CONSTANTS: BEGIN OF table,
                 jira_def         TYPE tabname VALUE 'YTTICKSYS_JIDEF',
                 jira_transitions TYPE tabname VALUE 'YTTICKSYS_JITRA',
               END OF table.

    DATA definitions TYPE ytticksys_jidef READ-ONLY.
    DATA transitions TYPE transition_set READ-ONLY.
    DATA status_assignee_fields TYPE jista_list READ-ONLY.
    DATA status_orders TYPE status_order_list READ-ONLY.
    DATA transport_instruction_fields TYPE jira_field_list READ-ONLY.
    DATA tcode_fields TYPE jira_field_list READ-ONLY.

    CLASS-METHODS get_instance
      RETURNING VALUE(instance) TYPE REF TO ycl_ticksys_jira_def
      RAISING   ycx_addict_table_content.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA singleton TYPE REF TO ycl_ticksys_jira_def.
    METHODS constructor RAISING ycx_addict_table_content.
ENDCLASS.



CLASS ycl_ticksys_jira_def IMPLEMENTATION.
  METHOD get_instance.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a singleton instance
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    instance = ycl_ticksys_jira_def=>singleton.

    IF instance IS INITIAL.
      instance = NEW #( ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Object creation
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    SELECT SINGLE * FROM ytticksys_jidef
           WHERE sysid = @sy-sysid
           INTO CORRESPONDING FIELDS OF @me->definitions.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid   = ycx_addict_table_content=>no_entry_for_objectid
          tabname  = ycl_ticksys_jira_def=>table-jira_def
          objectid = CONV #( sy-sysid ).
    ENDIF.

    IF me->definitions-url IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = ycl_ticksys_jira_def=>table-jira_def
          objectid  = CONV #( sy-sysid )
          fieldname = field-url.
    ENDIF.

    IF me->definitions-username IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = ycl_ticksys_jira_def=>table-jira_def
          objectid  = CONV #( sy-sysid )
          fieldname = field-username.
    ENDIF.

    IF me->definitions-password IS INITIAL.
      RAISE EXCEPTION TYPE ycx_addict_table_content
        EXPORTING
          textid    = ycx_addict_table_content=>entry_field_empty
          tabname   = ycl_ticksys_jira_def=>table-jira_def
          objectid  = CONV #( sy-sysid )
          fieldname = field-password.
    ENDIF.

    SELECT * FROM ytticksys_jitra                       "#EC CI_NOWHERE
             INTO TABLE @me->transitions.

    SELECT * FROM ytticksys_jista                       "#EC CI_NOWHERE
             ORDER BY status_id, priority
             INTO TABLE @me->status_assignee_fields.

    SELECT jira_field FROM ytticksys_jitif              "#EC CI_NOWHERE
           INTO TABLE @me->transport_instruction_fields.

    SELECT jira_field FROM ytticksys_jitcf              "#EC CI_NOWHERE
           INTO TABLE @me->tcode_fields.

    SELECT * FROM ytticksys_jisto                       "#EC CI_NOWHERE
             INTO TABLE @me->status_orders.
  ENDMETHOD.
ENDCLASS.
