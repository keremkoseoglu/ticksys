CLASS ycx_ticksys_assignee_update DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF ycx_ticksys_assignee_update,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '604',
        attr1 TYPE scx_attrname VALUE 'TICKET_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF ycx_ticksys_assignee_update.
    CONSTANTS:
      BEGIN OF new_assignee_not_found,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '606',
        attr1 TYPE scx_attrname VALUE 'TICKET_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF new_assignee_not_found.
    CONSTANTS:
      BEGIN OF preparation_error,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '605',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF preparation_error.

    DATA ticket_id TYPE yd_ticksys_ticket_id.

    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key OPTIONAL
                !previous LIKE previous                 OPTIONAL
                ticket_id TYPE yd_ticksys_ticket_id     OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycx_ticksys_assignee_update IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->ticket_id = ticket_id.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = ycx_ticksys_assignee_update.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
