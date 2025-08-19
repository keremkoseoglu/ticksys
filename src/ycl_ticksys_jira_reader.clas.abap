CLASS ycl_ticksys_jira_reader DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES string_range TYPE RANGE OF string.

    DATA issue_key_parent_rng TYPE string_range READ-ONLY.

    CLASS-METHODS get_instance
      IMPORTING ticsy_id      TYPE yd_ticksys_ticsy_id
      RETURNING VALUE(result) TYPE REF TO ycl_ticksys_jira_reader
      RAISING   ycx_addict_table_content.

    METHODS create_http_client
      IMPORTING url           TYPE clike
      RETURNING VALUE(result) TYPE REF TO if_http_client
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_statuses
      RETURNING VALUE(statuses) TYPE yif_ticksys_jira_api=>status_set
      RAISING   ycx_ticksys_ticketing_system.

    METHODS search_issues
      IMPORTING jql            TYPE string
                max_results    TYPE i OPTIONAL
      RETURNING VALUE(results) TYPE /ui5/cl_json_parser=>t_entry_map
      RAISING   ycx_ticksys_ticketing_system.

    METHODS get_jira_issue
      IMPORTING ticket_id     TYPE yd_ticksys_ticket_id
                bypass_cache  TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(output) TYPE yif_ticksys_jira_api=>issue_dict
      RAISING   ycx_ticksys_ticketing_system.

  PRIVATE SECTION.
    TYPES: BEGIN OF multiton_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
             obj      TYPE REF TO ycl_ticksys_jira_reader,
           END OF multiton_dict,

           multiton_set TYPE HASHED TABLE OF multiton_dict WITH UNIQUE KEY primary_key COMPONENTS ticsy_id.

    CLASS-DATA multitons TYPE multiton_set.

    DATA: defs                TYPE REF TO ycl_ticksys_jira_def,
          issue_cache         TYPE yif_ticksys_jira_api=>issue_set,
          status_cache        TYPE yif_ticksys_jira_api=>status_set,
          http_client_factory TYPE REF TO yif_ticksys_jira_http_clnt_fct.

    METHODS constructor
      IMPORTING ticsy_id TYPE yd_ticksys_ticsy_id
      RAISING   ycx_addict_table_content.
ENDCLASS.


CLASS ycl_ticksys_jira_reader IMPLEMENTATION.
  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Initial object access
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    me->defs                 = ycl_ticksys_jira_def=>get_instance( ticsy_id ).

    me->issue_key_parent_rng = VALUE #( option = ycl_addict_toolkit=>option-cp
                                        ( sign = ycl_addict_toolkit=>sign-include
                                          low  = '/issues/*' )
                                        ( sign = ycl_addict_toolkit=>sign-exclude
                                          low  = '/issues/*/*' ) ).
  ENDMETHOD.

  METHOD get_instance.
    TRY.
        DATA(mt) = REF #( multitons[ KEY primary_key
                                     ticsy_id = ticsy_id ] ).
      CATCH cx_sy_itab_line_not_found.
        INSERT VALUE #( ticsy_id = ticsy_id
                        obj      = NEW #( ticsy_id ) )
               INTO TABLE multitons REFERENCE INTO mt.
    ENDTRY.

    result = mt->obj.
  ENDMETHOD.

  METHOD create_http_client.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Creates a new HTTP client connecting to Jira
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    result = me->defs->get_jira_api( )->create_http_client( url ).
  ENDMETHOD.

  METHOD get_jira_issue.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Reads the given Jira issue from the server
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF bypass_cache = abap_true.
      DELETE me->issue_cache WHERE ticket_id = ticket_id.
    ENDIF.

    ASSIGN me->issue_cache[ KEY primary_key COMPONENTS ticket_id = ticket_id ]
           TO FIELD-SYMBOL(<cache>).

    IF sy-subrc <> 0.
      DATA(jira_api) = me->defs->get_jira_api( ).
      DATA(cache)    = jira_api->get_jira_issue( ticket_id ).
      INSERT cache INTO TABLE me->issue_cache ASSIGNING <cache>.
    ENDIF.

    output = <cache>.
  ENDMETHOD.

  METHOD get_statuses.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of statuses
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF me->status_cache IS INITIAL.
      DATA(jira_api)   = me->defs->get_jira_api( ).
      me->status_cache = jira_api->get_statuses( ).
    ENDIF.

    statuses = me->status_cache.
  ENDMETHOD.

  METHOD search_issues.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Runs a JQL search over Jira API
    " Full expand list if needed:
    " 'names,renderedFields,schema,transitions,operations,editmeta,changelog'
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(jira_api) = me->defs->get_jira_api( ).

    results = jira_api->search_issues( jql         = jql
                                       max_results = max_results ).
  ENDMETHOD.
ENDCLASS.
