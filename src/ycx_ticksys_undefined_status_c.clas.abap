CLASS ycx_ticksys_undefined_status_c DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF ticket_cant_be_set,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '009',
        attr1 TYPE scx_attrname VALUE 'TICKET_ID',
        attr2 TYPE scx_attrname VALUE 'STATUS_ID',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF ticket_cant_be_set.

    DATA ticket_id TYPE yd_ticksys_ticket_id.
    DATA status_id TYPE yd_ticksys_ticket_status_id.

    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key    OPTIONAL
                !previous LIKE previous                    OPTIONAL
                ticket_id TYPE yd_ticksys_ticket_id        OPTIONAL
                status_id TYPE yd_ticksys_ticket_status_id OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycx_ticksys_undefined_status_c IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->ticket_id = ticket_id.
    me->status_id = status_id.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
