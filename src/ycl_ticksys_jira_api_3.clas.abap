CLASS ycl_ticksys_jira_api_3 DEFINITION
  PUBLIC
  INHERITING FROM ycl_ticksys_jira_api_2
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS yif_ticksys_jira_api~search_issues  REDEFINITION.

    METHODS yif_ticksys_jira_api~get_jira_issue REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycl_ticksys_jira_api_3 IMPLEMENTATION.
  METHOD yif_ticksys_jira_api~search_issues.
    DATA(url) = |{ me->jira_def->definitions-url }/rest/api/3/search/jql| &&
                |?jql={ cl_http_utility=>escape_url( jql ) }| &&
                |&fields=*all| &&
                |&expand=names,renderedFields,schema,transitions,operations,editmeta,changelog| &&
                |{ COND #( WHEN max_results IS NOT INITIAL THEN |&maxResults={ max_results }| ) }|.

    results = yif_ticksys_jira_api~http_get_jira_rest_api( url ).
  ENDMETHOD.

  METHOD yif_ticksys_jira_api~get_jira_issue.
    " Preparation """""""""""""""""""""""""""""""""""""""""""""""""
    result = VALUE #( ticket_id = ticket_id
                      header    = VALUE #( ticket_id = ticket_id ) ).

    " Search """"""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(search_results) = yif_ticksys_jira_api~search_issues( jql         = |issuekey={ ticket_id }|
                                                               max_results = 1 ).

    " Validate """"""""""""""""""""""""""""""""""""""""""""""""""""
    IF NOT line_exists( search_results[ parent = '/issues/1' ] ).
      DATA(ticket_error) = NEW ycx_ticksys_ticket( textid    = ycx_ticksys_ticket=>ticket_not_found
                                                   ticsy_id  = me->jira_def->definitions-ticsy_id
                                                   ticket_id = ticket_id ).

      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid   = ycx_ticksys_ticketing_system=>ycx_ticksys_ticketing_system
                              previous = ticket_error ).
    ENDIF.

    " Read values """""""""""""""""""""""""""""""""""""""""""""""""
    result-header-internal_ticket_id = VALUE #( search_results[ parent = |/issues/1|
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-ticket_description = VALUE #( search_results[ parent = |/issues/1/fields|
                                                                name   = 'summary'
                                                ]-value OPTIONAL ).

    result-header-status_id          = VALUE #( search_results[ parent = '/issues/1/fields/status'
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-status_text        = VALUE #( search_results[ parent = '/issues/1/fields/status'
                                                                name   = 'name'
                                                ]-value OPTIONAL ).

    result-header-completed          = xsdbool( VALUE string( search_results[
                                                                  parent = '/issues/1/fields/status/statusCategory'
                                                                  name   = 'key'
                                                              ]-value OPTIONAL )
                                                = 'done' ).

    result-header-parent_ticket_id   = VALUE #( search_results[ parent = '/issues/1/fields/parent'
                                                                name   = 'key'
                                                ]-value OPTIONAL ).

    result-header-type_id            = VALUE #( search_results[ parent = '/issues/1/fields/issuetype'
                                                                name   = 'id'
                                                ]-value OPTIONAL ).

    result-header-type_text          = VALUE #( search_results[ parent = '/issues/1/fields/issuetype'
                                                                name   = 'name'
                                                ]-value OPTIONAL ).

    result-header-assignee           = VALUE #( search_results[ parent = '/issues/1/fields/assignee'
                                                                name   = 'displayName'
                                                ]-value OPTIONAL ).

    result-sub_tickets    = VALUE #( FOR GROUPS _value OF _entry IN search_results "#EC CI_SORTSEQ
                                     WHERE (     parent IN me->subtask_parent_rng
                                             AND name    = 'key' )
                                     GROUP BY _entry-value
                                     ( CONV #( _value ) ) ).

    result-linked_tickets = VALUE #( FOR GROUPS _value OF _entry IN search_results "#EC CI_SORTSEQ
                                     WHERE (     parent IN me->issue_link_parent_rng
                                             AND name    = 'key' )
                                     GROUP BY _entry-value
                                     ( CONV #( _value ) ) ).

    LOOP AT me->jira_def->status_assignee_fields
         INTO DATA(_jsaf)
         GROUP BY ( jira_field = _jsaf-jira_field )
         ASSIGNING FIELD-SYMBOL(<jsaf>).

      DATA(assignee_found) = abap_false.

      LOOP AT search_results REFERENCE INTO DATA(assignee_result)
           WHERE     parent  = |/issues/1/fields/{ <jsaf>-jira_field }|
                 AND name    = me->jira_def->definitions-assignee_fld
                 AND value  <> yif_ticksys_jira_api=>json_null.

        INSERT VALUE yif_ticksys_jira_api=>custom_field_value_dict( jira_field = <jsaf>-jira_field
                                                                    value      = assignee_result->value )
               INTO TABLE result-custom_fields.

        assignee_found = abap_true.
        EXIT.
      ENDLOOP.

      CHECK assignee_found = abap_true.
      EXIT.
    ENDLOOP.

    LOOP AT me->jira_def->transport_instruction_fields ASSIGNING FIELD-SYMBOL(<tif>).
      ASSIGN search_results[ parent = |/issues/1/renderedFields|
                             name   = <tif> ]
             TO FIELD-SYMBOL(<tif_value>).

      CHECK     sy-subrc           = 0
            AND <tif_value>-value IS NOT INITIAL
            AND <tif_value>-value <> yif_ticksys_jira_api=>json_null.

      result-transport_instructions =
        |{ result-transport_instructions }| &&
        |{ COND #( WHEN result-transport_instructions IS NOT INITIAL THEN ` ` ) }| &&
        |{ <tif_value>-value }|.
    ENDLOOP.

    REPLACE ALL OCCURRENCES OF '<p>' IN result-transport_instructions WITH space.
    REPLACE ALL OCCURRENCES OF '</p>' IN result-transport_instructions WITH space.

    LOOP AT me->jira_def->tcode_fields ASSIGNING FIELD-SYMBOL(<tcf>).
      APPEND LINES OF VALUE yif_ticksys_ticketing_system=>tcode_list( FOR _entry IN search_results
                                                                      WHERE (     parent  = |/issues/1/fields/{ <tcf> }|
                                                                              AND value  <> yif_ticksys_jira_api=>json_null )
                                                                      ( CONV #( _entry-value ) ) )
             TO result-tcodes.
    ENDLOOP.

    LOOP AT me->jira_def->main_module_fields ASSIGNING FIELD-SYMBOL(<mm>).
      DATA(mm_parent) = |/issues/1/fields/{ <mm> }|.

      LOOP AT search_results ASSIGNING FIELD-SYMBOL(<mm_result>)
           WHERE     parent  = mm_parent
                 AND value  IS NOT INITIAL.

        CASE <mm_result>-name.
          WHEN `id`. result-header-main_module_id   = <mm_result>-value.
          WHEN `value`. result-header-main_module_text = <mm_result>-value.
        ENDCASE.
      ENDLOOP.
    ENDLOOP.

    LOOP AT me->jira_def->platform_fields ASSIGNING FIELD-SYMBOL(<plf>).
      APPEND LINES OF VALUE yif_ticksys_ticketing_system=>tcode_list( FOR _entry IN search_results
                                                                      WHERE (     parent  = |/issues/1/fields/{ <plf> }|
                                                                              AND name    = 'value'
                                                                              AND value  <> yif_ticksys_jira_api=>json_null )
                                                                      ( CONV #( _entry-value ) ) )
             TO result-platforms.
    ENDLOOP.

    result-header-platform = VALUE #( result-platforms[ 1 ] OPTIONAL ).

    DATA(location_parent_rng) = get_location_parent_rng_lazy( ).

    LOOP AT search_results REFERENCE INTO DATA(location_value)
         WHERE     parent IN location_parent_rng->*  "#EC CI_SORTSEQ
               AND name    = 'value'
               AND value  IS NOT INITIAL
               AND value  <> yif_ticksys_jira_api=>json_null.

      result-header-location =
        |{ result-header-location }| &&
        |{ COND #( WHEN result-header-location IS NOT INITIAL THEN ` ` ) }| &&
        |{ location_value->value }|.
    ENDLOOP.

    SORT result-linked_tickets.
    DELETE ADJACENT DUPLICATES FROM result-linked_tickets.

    SORT result-sub_tickets.
    DELETE ADJACENT DUPLICATES FROM result-sub_tickets.

    SORT result-tcodes.
    DELETE ADJACENT DUPLICATES FROM result-tcodes.
  ENDMETHOD.
ENDCLASS.
