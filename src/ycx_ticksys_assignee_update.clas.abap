class YCX_TICKSYS_ASSIGNEE_UPDATE definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  interfaces IF_T100_DYN_MSG .
  interfaces IF_T100_MESSAGE .

  constants:
    begin of YCX_TICKSYS_ASSIGNEE_UPDATE,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '604',
      attr1 type scx_attrname value 'TICKET_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of YCX_TICKSYS_ASSIGNEE_UPDATE .
  constants:
    begin of NEW_ASSIGNEE_NOT_FOUND,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '606',
      attr1 type scx_attrname value 'TICKET_ID',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NEW_ASSIGNEE_NOT_FOUND .
  constants:
    begin of PREPARATION_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '605',
      attr1 type scx_attrname value '',
      attr2 type scx_attrname value '',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of PREPARATION_ERROR .
  data TICKET_ID type YD_ADDICT_TICKET_ID .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !TICKET_ID type YD_ADDICT_TICKET_ID optional .
protected section.
private section.
ENDCLASS.



CLASS YCX_TICKSYS_ASSIGNEE_UPDATE IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->TICKET_ID = TICKET_ID .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = YCX_TICKSYS_ASSIGNEE_UPDATE .
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
  endmethod.
ENDCLASS.
