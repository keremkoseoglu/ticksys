*"* use this source file for your ABAP unit test classes
CLASS lcl_test DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS sanipak_get_jira_issue       FOR TESTING.
    METHODS sanipak_get_jira_cloud_issue FOR TESTING.

    METHODS is_sanipak_system            RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_test IMPLEMENTATION.
  METHOD sanipak_get_jira_issue.
    CHECK is_sanipak_system( ).

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
    CHECK is_sanipak_system( ).

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

  METHOD is_sanipak_system.
    result = xsdbool(    sy-sysid = 'TDE'
                      OR sy-sysid = 'TQE'
                      OR sy-sysid = 'TPE'
                      OR sy-sysid = 'TDF'
                      OR sy-sysid = 'TQF'
                      OR sy-sysid = 'TPF' ).
  ENDMETHOD.
ENDCLASS.
