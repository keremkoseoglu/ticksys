INTERFACE yif_ticksys_ticketing_system
  PUBLIC .

  CONSTANTS: BEGIN OF class,
               me TYPE seoclsname VALUE 'YIF_TICKSYS_TICKETING_SYSTEM',
             END OF class.

  METHODS is_ticket_id_valid
    IMPORTING !ticket_key   TYPE yif_addict_system_rules=>ticket_key_dict
    RETURNING VALUE(output) TYPE abap_bool
    RAISING   ycx_ticksys_ticketing_system.

ENDINTERFACE.
