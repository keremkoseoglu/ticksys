INTERFACE yif_ticksys_ticketing_system
  PUBLIC.

  TYPES string_list    TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  TYPES tcode_list     TYPE STANDARD TABLE OF tcode WITH KEY table_line.
  TYPES ticket_id_list TYPE STANDARD TABLE OF yd_ticksys_ticket_id WITH KEY table_line.
  TYPES status_id_list TYPE STANDARD TABLE OF yd_ticksys_ticket_status_id WITH KEY table_line.
  TYPES type_id_list   TYPE STANDARD TABLE OF yd_ticksys_ticket_type_id WITH KEY table_line.
  TYPES platform_list  TYPE STANDARD TABLE OF yd_ticksys_ticket_platform WITH KEY table_line.

  TYPES: BEGIN OF status_dict,
           status_id   TYPE yd_ticksys_ticket_status_id,
           status_text TYPE yd_ticksys_ticket_status_text,
         END OF status_dict.

  TYPES: BEGIN OF ticket_status_dict,
           ticket_id TYPE yd_ticksys_ticket_id,
           status_id TYPE yd_ticksys_ticket_status_id,
         END OF ticket_status_dict,

         ticket_status_list TYPE STANDARD TABLE OF ticket_status_dict WITH KEY ticket_id.

  TYPES: BEGIN OF ticket_key_dict,
           ticsy_id  TYPE yd_ticksys_ticsy_id,
           ticket_id TYPE yd_ticksys_ticket_id,
         END OF ticket_key_dict,

         ticket_key_list TYPE STANDARD TABLE OF ticket_key_dict WITH KEY ticsy_id ticket_id.

  CONSTANTS: BEGIN OF class,
               me TYPE seoclsname VALUE 'YIF_TICKSYS_TICKETING_SYSTEM',
             END OF class.

  METHODS is_ticket_id_valid DEFAULT IGNORE
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(output) TYPE abap_bool
    RAISING   ycx_ticksys_ticketing_system.

  METHODS can_set_ticket_to_status DEFAULT IGNORE
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
              status_id     TYPE yd_ticksys_ticket_status_id
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_ticket_header DEFAULT IGNORE
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(output) TYPE ysticksys_ticket_header
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_transport_instructions DEFAULT IGNORE
    IMPORTING ticket_id           TYPE yd_ticksys_ticket_id
    RETURNING VALUE(instructions) TYPE string_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_sub_tickets DEFAULT IGNORE
    IMPORTING !parent         TYPE yd_ticksys_ticket_id
    RETURNING VALUE(children) TYPE ticket_id_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_linked_tickets DEFAULT IGNORE
    IMPORTING ticket_id      TYPE yd_ticksys_ticket_id
    RETURNING VALUE(tickets) TYPE ticket_id_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_related_tcodes DEFAULT IGNORE
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(tcodes) TYPE tcode_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_tickets_related_to_tcodes DEFAULT IGNORE
    IMPORTING tcodes         TYPE tcode_list
    RETURNING VALUE(tickets) TYPE ticket_id_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_earliest_status DEFAULT IGNORE
    IMPORTING statuses        TYPE status_id_list
    RETURNING VALUE(earliest) TYPE status_dict
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_tickets_with_status DEFAULT IGNORE
    IMPORTING statuses       TYPE status_id_list
              !types         TYPE type_id_list OPTIONAL
    RETURNING VALUE(tickets) TYPE ticket_status_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_modified_tickets DEFAULT IGNORE
    IMPORTING begda          TYPE dats
              endda          TYPE dats
              users          TYPE string_list
    RETURNING VALUE(tickets) TYPE ticket_id_list
    RAISING   ycx_ticksys_ticketing_system.

  METHODS set_ticket_status DEFAULT IGNORE
    IMPORTING ticket_id TYPE yd_ticksys_ticket_id
              status_id TYPE yd_ticksys_ticket_status_id
    RAISING   ycx_ticksys_ticketing_system.

  METHODS set_ticket_assignee DEFAULT IGNORE
    IMPORTING ticket_id TYPE yd_ticksys_ticket_id
              assignee  TYPE clike
    RAISING   ycx_ticksys_ticketing_system.

  METHODS set_ticket_assignee_for_status DEFAULT IGNORE
    IMPORTING ticket_id TYPE yd_ticksys_ticket_id
              status_id TYPE yd_ticksys_ticket_status_id
    RAISING   ycx_ticksys_ticketing_system.

  METHODS display_ticket DEFAULT IGNORE
    IMPORTING ticket_id TYPE yd_ticksys_ticket_id
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_ticsy_id DEFAULT IGNORE
    RETURNING VALUE(result) TYPE yd_ticksys_ticsy_id.

ENDINTERFACE.
