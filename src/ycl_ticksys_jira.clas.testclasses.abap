*"* use this source file for your ABAP unit test classes
CLASS lcl_test DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS jira_cloud_bug_task_to_qa FOR TESTING.
ENDCLASS.


CLASS lcl_test IMPLEMENTATION.
  METHOD jira_cloud_bug_task_to_qa.
    IF NOT ( sy-sysid = 'TDF' AND sy-datum = '20250820' ).
      cl_abap_unit_assert=>abort( msg  = 'No test case for cloud bug task to QA'
                                  quit = if_aunit_constants=>method ).
    ENDIF.

    DATA(jira_sys) = CAST yif_ticksys_ticketing_system( NEW ycl_ticksys_jira( 'JIRA_CLOUD' ) ).

    DATA(test_ticket_id) = CONV yd_ticksys_ticket_id( 'SD-849' ).
    DATA(moved_to_qa_status) = CONV yd_ticksys_ticket_status_id( '10068' ).

    TRY.
        " Can we set status?
        DATA(can_set_ticket_to_qa) = jira_sys->can_set_ticket_to_status( ticket_id = test_ticket_id
                                                                         status_id = moved_to_qa_status ).

        cl_abap_unit_assert=>assert_true( can_set_ticket_to_qa ).

        " Set status
        jira_sys->set_ticket_status( ticket_id = test_ticket_id
                                     status_id = moved_to_qa_status ).

        " Set assignee
        jira_sys->set_ticket_assignee_for_status( ticket_id = test_ticket_id
                                                  status_id = moved_to_qa_status ).

      CATCH ycx_ticksys_ticketing_system INTO DATA(ticksy_error).
        cl_abap_unit_assert=>fail( msg = ticksy_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
