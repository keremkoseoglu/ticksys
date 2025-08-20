*"* use this source file for your ABAP unit test classes
CLASS lcl_test DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS sanipak_get_jira_issue       FOR TESTING.
    METHODS sanipak_get_jira_cloud_issue FOR TESTING.
    METHODS sanipak_cloud_sd_856         FOR TESTING.
    METHODS sanipak_cloud_sd_847         FOR TESTING.

    METHODS is_sanipak_system            RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_test IMPLEMENTATION.
  METHOD sanipak_get_jira_issue.
    IF NOT is_sanipak_system( ).
      cl_abap_unit_assert=>abort( msg  = 'Not Sanipak system'
                                  quit = if_aunit_constants=>method ).
    ENDIF.

    TRY.
        DATA(jira_reader) = ycl_ticksys_jira_reader=>get_instance( 'JIRA' ).

      CATCH ycx_addict_table_content INTO DATA(ticksys_error).
        cl_abap_unit_assert=>fail( msg = ticksys_error->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(jira_issue) = jira_reader->get_jira_issue( ticket_id    = 'VOL-31281'
                                                        bypass_cache = abap_true ).
      CATCH ycx_ticksys_ticketing_system INTO DATA(ticket_error).
        cl_abap_unit_assert=>fail( msg = ticket_error->get_text( ) ).
        RETURN.
    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial( jira_issue ).
  ENDMETHOD.

  METHOD sanipak_get_jira_cloud_issue.
    IF NOT is_sanipak_system( ).
      cl_abap_unit_assert=>abort( msg  = 'Not Sanipak system'
                                  quit = if_aunit_constants=>method ).
    ENDIF.

    TRY.
        DATA(jira_reader) = ycl_ticksys_jira_reader=>get_instance( 'JIRA_CLOUD' ).

      CATCH ycx_addict_table_content INTO DATA(ticksys_error).
        cl_abap_unit_assert=>fail( msg = ticksys_error->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(jira_issue) = jira_reader->get_jira_issue( ticket_id    = 'SD-855'
                                                        bypass_cache = abap_true ).
      CATCH ycx_ticksys_ticketing_system INTO DATA(ticket_error).
        cl_abap_unit_assert=>fail( msg = ticket_error->get_text( ) ).
        RETURN.
    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial( jira_issue ).
  ENDMETHOD.

  METHOD sanipak_cloud_sd_856.
    IF NOT is_sanipak_system( ).
      cl_abap_unit_assert=>abort( msg  = 'Not Sanipak system'
                                  quit = if_aunit_constants=>method ).
    ENDIF.

    TRY.
        DATA(jira_reader) = ycl_ticksys_jira_reader=>get_instance( 'JIRA_CLOUD' ).

      CATCH ycx_addict_table_content INTO DATA(ticksys_error).
        cl_abap_unit_assert=>fail( msg = ticksys_error->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(jira_issue) = jira_reader->get_jira_issue( ticket_id    = 'SD-856'
                                                        bypass_cache = abap_true ).
      CATCH ycx_ticksys_ticketing_system INTO DATA(ticket_error).
        cl_abap_unit_assert=>fail( msg = ticket_error->get_text( ) ).
        RETURN.
    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial( jira_issue-transport_instructions ).
    cl_abap_unit_assert=>assert_not_initial( jira_issue-linked_tickets ).
  ENDMETHOD.

  METHOD sanipak_cloud_sd_847.
    IF NOT is_sanipak_system( ).
      cl_abap_unit_assert=>abort( msg  = 'Not Sanipak system'
                                  quit = if_aunit_constants=>method ).
    ENDIF.

    TRY.
        DATA(jira_reader) = ycl_ticksys_jira_reader=>get_instance( 'JIRA_CLOUD' ).

      CATCH ycx_addict_table_content INTO DATA(ticksys_error).
        cl_abap_unit_assert=>fail( msg = ticksys_error->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        DATA(jira_issue) = jira_reader->get_jira_issue( ticket_id    = 'SD-847'
                                                        bypass_cache = abap_true ).
      CATCH ycx_ticksys_ticketing_system INTO DATA(ticket_error).
        cl_abap_unit_assert=>fail( msg = ticket_error->get_text( ) ).
        RETURN.
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( exp = 'SAP PM'
                                        act = jira_issue-header-main_module_text ).
  ENDMETHOD.

  METHOD is_sanipak_system.
    result = xsdbool(    sy-sysid = 'TDE'
                      OR sy-sysid = 'TQE'
                      OR sy-sysid = 'TPE'
                      OR sy-sysid = 'TDF'
                      OR sy-sysid = 'TQF'
                      OR sy-sysid = 'TPF' ).
  ENDMETHOD.
ENDCLASS.
