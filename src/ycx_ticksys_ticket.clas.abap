class YCX_TICKSYS_TICKET definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  interfaces IF_T100_DYN_MSG .
  interfaces IF_T100_MESSAGE .

  constants:
    begin of VALIDATION_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '017',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value 'TICKET_ID',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of VALIDATION_ERROR .
  constants:
    begin of NO_UPDATE_RULE_FOUND,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '000',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value 'TICKET_ID',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of NO_UPDATE_RULE_FOUND .
  constants:
    begin of STATUS_UPDATE_ERROR,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '001',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value 'TICKET_ID',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of STATUS_UPDATE_ERROR .
  constants:
    begin of TICKET_NOT_FOUND,
      msgid type symsgid value 'YTICKSYS',
      msgno type symsgno value '005',
      attr1 type scx_attrname value 'TICSY_ID',
      attr2 type scx_attrname value 'TICKET_ID',
      attr3 type scx_attrname value '',
      attr4 type scx_attrname value '',
    end of TICKET_NOT_FOUND .
  data TICSY_ID type YD_TICKSYS_TICSY_ID .
  data TICKET_ID type YD_ADDICT_TICKET_ID .

  methods CONSTRUCTOR
    importing
      !TEXTID like IF_T100_MESSAGE=>T100KEY optional
      !PREVIOUS like PREVIOUS optional
      !TICSY_ID type YD_TICKSYS_TICSY_ID optional
      !TICKET_ID type YD_ADDICT_TICKET_ID optional .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCX_TICKSYS_TICKET IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
PREVIOUS = PREVIOUS
.
me->TICSY_ID = TICSY_ID .
me->TICKET_ID = TICKET_ID .
clear me->textid.
if textid is initial.
  IF_T100_MESSAGE~T100KEY = IF_T100_MESSAGE=>DEFAULT_TEXTID.
else.
  IF_T100_MESSAGE~T100KEY = TEXTID.
endif.
  endmethod.
ENDCLASS.
