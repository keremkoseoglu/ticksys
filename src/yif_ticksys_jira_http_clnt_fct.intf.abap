INTERFACE yif_ticksys_jira_http_clnt_fct
  PUBLIC.

  METHODS create_default_client
    IMPORTING url                TYPE clike
    RETURNING VALUE(result) TYPE REF TO if_http_client
    RAISING   ycx_ticksys_ticketing_system.

  METHODS create_basic_auth_client
    IMPORTING url                TYPE clike
    RETURNING VALUE(result) TYPE REF TO if_http_client
    RAISING   ycx_ticksys_ticketing_system.

  METHODS create_api_token_client
    IMPORTING url                TYPE clike
    RETURNING VALUE(result) TYPE REF TO if_http_client
    RAISING   ycx_ticksys_ticketing_system.

ENDINTERFACE.
