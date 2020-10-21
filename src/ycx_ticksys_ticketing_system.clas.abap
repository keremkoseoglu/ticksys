class YCX_TICKSYS_TICKETING_SYSTEM definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  interfaces IF_T100_DYN_MSG .
  interfaces IF_T100_MESSAGE .

  constants:
    begin of YCX_TICKSYS_TICKETING_SYSTEM,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '011',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of YCX_TICKSYS_TICKETING_SYSTEM .
  constants:
    begin of HTTP_REQUEST_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '013',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of HTTP_REQUEST_ERROR .
  constants:
    begin of HTTP_RESPONSE_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '014',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of HTTP_RESPONSE_ERROR .
  constants:
    begin of HTTP_RESPONSE_PARSE_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '015',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of HTTP_RESPONSE_PARSE_ERROR .
  constants:
    begin of HTTP_RESPONDED_WITH_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '016',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of HTTP_RESPONDED_WITH_ERROR .
  data TICSY_ID type YD_TICKSYS_TICSY_ID .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !TICSY_ID type YD_TICKSYS_TICSY_ID optional .
protected section.
private section.
ENDCLASS.



CLASS YCX_TICKSYS_TICKETING_SYSTEM IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->TICSY_ID = TICSY_ID .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = YCX_TICKSYS_TICKETING_SYSTEM .
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
  endmethod.
ENDCLASS.
