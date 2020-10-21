INTERFACE yif_ticksys_ticketing_system
  PUBLIC .

  TYPES: BEGIN OF ticket_key_dict,
           ticsy_id  TYPE yd_ticksys_ticsy_id,
           ticket_id TYPE yd_addict_ticket_id,
         END OF ticket_key_dict.

  CONSTANTS: BEGIN OF class,
               me TYPE seoclsname VALUE 'YIF_TICKSYS_TICKETING_SYSTEM',
             END OF class.

  METHODS is_ticket_id_valid
    IMPORTING !ticket_key   TYPE ticket_key_dict
    RETURNING VALUE(output) TYPE abap_bool
    RAISING   ycx_ticksys_ticketing_system.

ENDINTERFACE.
