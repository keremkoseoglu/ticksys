INTERFACE yif_ticksys_ticket_sys_hub
  PUBLIC.

  TYPES ticketing_system_set TYPE HASHED TABLE OF ytticksys_ticsy
                             WITH UNIQUE KEY primary_key COMPONENTS ticsy_id.

  METHODS read_ticket_header
    IMPORTING ticket_id       TYPE yd_ticksys_ticket_id
              known_ticsy_id  TYPE yd_ticksys_ticsy_id OPTIONAL
    EXPORTING ticket_header   TYPE ysticksys_ticket_header
              ticket_ticsy_id TYPE yd_ticksys_ticsy_id
    RAISING   ycx_ticksys_ticket.

  METHODS get_first_system_with_ticket
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(result) TYPE yd_ticksys_ticsy_id
    RAISING   ycx_ticksys_ticket.

  METHODS get_systems_with_ticket
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(result) TYPE ticketing_system_set.

  METHODS get_all_ticketing_systems
    RETURNING VALUE(result) TYPE ticketing_system_set.

ENDINTERFACE.
