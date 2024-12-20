CLASS ycl_ticksys_jira_http_clnt_fct DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_ticksys_jira_http_clnt_fct.

    METHODS constructor IMPORTING jira_def TYPE REF TO ycl_ticksys_jira_def.

  PRIVATE SECTION.
    DATA jira_def TYPE REF TO ycl_ticksys_jira_def.
ENDCLASS.


CLASS ycl_ticksys_jira_http_clnt_fct IMPLEMENTATION.
  METHOD constructor.
    me->jira_def = jira_def.
  ENDMETHOD.

  METHOD yif_ticksys_jira_http_clnt_fct~create_default_client.
    result = COND #( WHEN me->jira_def->definitions-api_token IS NOT INITIAL
                     THEN yif_ticksys_jira_http_clnt_fct~create_api_token_client( url )
                     ELSE yif_ticksys_jira_http_clnt_fct~create_basic_auth_client( url ) ).
  ENDMETHOD.

  METHOD yif_ticksys_jira_http_clnt_fct~create_api_token_client.
    cl_http_client=>create_by_url( EXPORTING  url                = CONV #( url )
                                   IMPORTING  client             = result
                                   EXCEPTIONS argument_not_found = 1
                                              plugin_not_active  = 2
                                              internal_error     = 3
                                              OTHERS             = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid   = ycx_ticksys_ticketing_system=>http_client_creation_error
                              ticsy_id = me->jira_def->definitions-ticsy_id ).
    ENDIF.

    result->request->set_version( if_http_request=>co_protocol_version_1_0 ).

    DATA(encoded_token_string) = cl_http_utility=>encode_base64(
                                     |{ me->jira_def->definitions-username }:{ me->jira_def->definitions-api_token }| ).

    ##NO_TEXT
    result->request->set_header_field( name  = 'Authorization'
                                       value = |Basic { encoded_token_string }| ).
  ENDMETHOD.

  METHOD yif_ticksys_jira_http_clnt_fct~create_basic_auth_client.
    cl_http_client=>create_by_url( EXPORTING  url                = CONV #( url )
                                   IMPORTING  client             = result
                                   EXCEPTIONS argument_not_found = 1
                                              plugin_not_active  = 2
                                              internal_error     = 3
                                              OTHERS             = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW ycx_ticksys_ticketing_system(
                              textid   = ycx_ticksys_ticketing_system=>http_client_creation_error
                              ticsy_id = me->jira_def->definitions-ticsy_id ).
    ENDIF.

    result->request->set_version( if_http_request=>co_protocol_version_1_0 ).

    result->authenticate( username = CONV #( me->jira_def->definitions-username )
                          password = CONV #( me->jira_def->definitions-password ) ).
  ENDMETHOD.
ENDCLASS.
