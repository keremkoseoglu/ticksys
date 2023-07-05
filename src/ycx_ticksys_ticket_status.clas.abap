CLASS ycx_ticksys_ticket_status DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF invalid_status_id,
        msgid TYPE symsgid      VALUE 'YTICKSYS',
        msgno TYPE symsgno      VALUE '004',
        attr1 TYPE scx_attrname VALUE 'STATUS_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_status_id.

    DATA status_id TYPE yd_ticksys_ticket_status_id.

    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key    OPTIONAL
                !previous LIKE previous                    OPTIONAL
                status_id TYPE yd_ticksys_ticket_status_id OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycx_ticksys_ticket_status IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->status_id = status_id.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
