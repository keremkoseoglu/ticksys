CLASS ycx_ticksys_ticketing_system DEFINITION
  PUBLIC
  INHERITING FROM ycx_addict_ticketing_system
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF ycx_ticksys_ticketing_system,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '011',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF ycx_ticksys_ticketing_system .
    CONSTANTS:
      BEGIN OF http_request_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '013',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF http_request_error .
    CONSTANTS:
      BEGIN OF http_response_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '014',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF http_response_error .
    CONSTANTS:
      BEGIN OF http_response_parse_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '015',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF http_response_parse_error .
    CONSTANTS:
      BEGIN OF http_responded_with_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '016',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF http_responded_with_error .
    CONSTANTS:
      BEGIN OF http_client_creation_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '012',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF http_client_creation_error .
    CONSTANTS:
      BEGIN OF status_update_error,
        msgid TYPE symsgid VALUE 'YTICKSYS',
        msgno TYPE symsgno VALUE '018',
        attr1 TYPE scx_attrname VALUE 'TICSY_ID',
        attr2 TYPE scx_attrname VALUE 'TICKET_ID',
        attr3 TYPE scx_attrname VALUE 'STATUS_ID',
        attr4 TYPE scx_attrname VALUE '',
      END OF status_update_error .
    DATA ticsy_id TYPE yd_addict_ticsy_id .
    DATA ticket_id TYPE yd_addict_ticket_id .
    DATA status_id TYPE yd_addict_ticket_status_id .

    METHODS constructor
      IMPORTING
        !textid    LIKE if_t100_message=>t100key OPTIONAL
        !previous  LIKE previous OPTIONAL
        !ticsy_id  TYPE yd_ticksys_ticsy_id OPTIONAL
        !ticket_id TYPE yd_addict_ticket_id OPTIONAL
        !status_id TYPE yd_addict_ticket_status_id OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycx_ticksys_ticketing_system IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.

    me->ticsy_id = ticsy_id .
    me->ticket_id = ticket_id.
    me->status_id = status_id.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = ycx_ticksys_ticketing_system .
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
