class YCX_TICKSYS_TICKET_STATUS definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  interfaces IF_T100_DYN_MSG .
  interfaces IF_T100_MESSAGE .

  constants:
    begin of INVALID_STATUS_ID,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '004',
      attr1 type scx_attrname value 'STATUS_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of INVALID_STATUS_ID .
  data STATUS_ID type YD_ADDICT_TICKET_STATUS_ID .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !STATUS_ID type YD_ADDICT_TICKET_STATUS_ID optional .
protected section.
private section.
ENDCLASS.



CLASS YCX_TICKSYS_TICKET_STATUS IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->STATUS_ID = STATUS_ID .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
  endmethod.
ENDCLASS.
