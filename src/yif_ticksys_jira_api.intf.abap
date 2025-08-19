INTERFACE yif_ticksys_jira_api
  PUBLIC.

  TYPES: BEGIN OF bin_dict,
           line TYPE x LENGTH 255,
         END OF bin_dict,

         bin_list TYPE STANDARD TABLE OF bin_dict WITH EMPTY KEY.

  TYPES status_set TYPE HASHED TABLE OF yif_ticksys_ticketing_system=>status_dict
                   WITH UNIQUE KEY primary_key COMPONENTS status_id.

  TYPES: BEGIN OF custom_field_value_dict,
           jira_field TYPE yd_ticksys_jira_field,
           value      TYPE string,
         END OF custom_field_value_dict,

         custom_field_value_set TYPE HASHED TABLE OF custom_field_value_dict
                                WITH UNIQUE KEY primary_key COMPONENTS jira_field.

  TYPES: BEGIN OF issue_dict,
           ticket_id              TYPE ysticksys_ticket_header-ticket_id,
           header                 TYPE ysticksys_ticket_header,
           custom_fields          TYPE custom_field_value_set,
           sub_tickets            TYPE yif_ticksys_ticketing_system=>ticket_id_list,
           linked_tickets         TYPE yif_ticksys_ticketing_system=>ticket_id_list,
           tcodes                 TYPE yif_ticksys_ticketing_system=>tcode_list,
           transport_instructions TYPE string,
           platforms              TYPE yif_ticksys_ticketing_system=>platform_list,
         END OF issue_dict.

    TYPES issue_set TYPE HASHED TABLE OF issue_dict
                    WITH UNIQUE KEY primary_key COMPONENTS ticket_id.

  CONSTANTS: BEGIN OF http_return,
               ok TYPE i VALUE 200,
             END OF http_return.

  CONSTANTS json_null TYPE text4 VALUE 'null'.

  METHODS set_jira_def IMPORTING jira_def TYPE REF TO ycl_ticksys_jira_def.

  METHODS search_issues
    IMPORTING jql            TYPE string
              max_results    TYPE i OPTIONAL
    RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
    RAISING   ycx_ticksys_ticketing_system.

  METHODS http_get_jira_rest_api
    IMPORTING url            TYPE string
    RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
    RAISING   ycx_ticksys_ticketing_system.

  METHODS create_http_client
    IMPORTING url           TYPE clike
    RETURNING VALUE(result) TYPE REF TO if_http_client
    RAISING   ycx_ticksys_ticketing_system.

  METHODS replace_regex_in_json
    CHANGING !json TYPE string.

  METHODS get_statuses
    RETURNING VALUE(result) TYPE status_set
    RAISING   ycx_ticksys_ticketing_system.

  METHODS get_jira_issue
    IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
    RETURNING VALUE(result) TYPE issue_dict
    RAISING   ycx_ticksys_ticketing_system.

ENDINTERFACE.
