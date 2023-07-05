CLASS ycx_ticksys_ticket DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF validation_error,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '017',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE 'TICKET_ID',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF validation_error.
    CONSTANTS:
      BEGIN OF no_update_rule_found,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '000',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE 'TICKET_ID',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_update_rule_found.
    CONSTANTS:
      BEGIN OF status_update_error,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE 'TICKET_ID',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF status_update_error.
    CONSTANTS:
      BEGIN OF ticket_not_found,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '005',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE 'TICKET_ID',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF ticket_not_found.

    DATA ticsy_id  TYPE yd_ticksys_ticsy_id.
    DATA ticket_id TYPE yd_ticksys_ticket_id.

    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key OPTIONAL
                !previous LIKE previous                 OPTIONAL
                ticsy_id  TYPE yd_ticksys_ticsy_id      OPTIONAL
                ticket_id TYPE yd_ticksys_ticket_id     OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycx_ticksys_ticket IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->ticsy_id  = ticsy_id.
    me->ticket_id = ticket_id.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
