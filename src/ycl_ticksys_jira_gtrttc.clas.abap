CLASS ycl_ticksys_jira_gtrttc DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS get_instance
      IMPORTING ticsy_id      TYPE yd_ticksys_ticsy_id
      RETURNING VALUE(result) TYPE REF TO ycl_ticksys_jira_gtrttc
      RAISING   ycx_addict_table_content.

    METHODS execute
      IMPORTING tcodes         TYPE yif_ticksys_ticketing_system=>tcode_list
      RETURNING VALUE(tickets) TYPE yif_ticksys_ticketing_system=>ticket_id_list
      RAISING   ycx_ticksys_ticketing_system.

  PRIVATE SECTION.
    TYPES: BEGIN OF tcode_ticket_dict,
             tcode   TYPE tcode,
             tickets TYPE yif_ticksys_ticketing_system=>ticket_id_list,
           END OF tcode_ticket_dict,

           tcode_ticket_set TYPE HASHED TABLE OF tcode_ticket_dict
           WITH UNIQUE KEY primary_key COMPONENTS tcode.

    TYPES: BEGIN OF multiton_dict,
             ticsy_id TYPE yd_ticksys_ticsy_id,
             obj      TYPE REF TO ycl_ticksys_jira_gtrttc,
           END OF multiton_dict,

           multiton_set TYPE HASHED TABLE OF multiton_dict WITH UNIQUE KEY primary_key COMPONENTS ticsy_id.

    CLASS-DATA multitons TYPE multiton_set.

    DATA defs               TYPE REF TO ycl_ticksys_jira_def.
    DATA reader             TYPE REF TO ycl_ticksys_jira_reader.
    DATA tcode_ticket_cache TYPE tcode_ticket_set.

    METHODS constructor
      IMPORTING ticsy_id TYPE yd_ticksys_ticsy_id
      RAISING   ycx_addict_table_content.
ENDCLASS.


CLASS ycl_ticksys_jira_gtrttc IMPLEMENTATION.
  METHOD constructor.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Object creation
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    me->defs   = ycl_ticksys_jira_def=>get_instance( ticsy_id ).
    me->reader = ycl_ticksys_jira_reader=>get_instance( ticsy_id ).
  ENDMETHOD.

  METHOD execute.
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Returns a list of tickets related to the given TCodes
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    TRY.
        LOOP AT tcodes ASSIGNING FIELD-SYMBOL(<tcode>).
          ASSIGN me->tcode_ticket_cache[ KEY primary_key COMPONENTS tcode = <tcode> ]
                 TO FIELD-SYMBOL(<cache>).

          IF sy-subrc <> 0.
            DATA(new_cache) = VALUE tcode_ticket_dict( tcode = <tcode> ).

            LOOP AT me->defs->tcode_fields ASSIGNING FIELD-SYMBOL(<tcode_field>).
              DATA(jql_field) = <tcode_field>.

              IF jql_field CS 'customfield_'.
                DATA(split1) = || ##NEEDED.
                DATA(split2) = ||.
                SPLIT jql_field AT '_' INTO split1 split2.
                jql_field = |cf[{ split2 }]|.
              ENDIF.

              DATA(results) = me->reader->search_issues( |{ jql_field }={ <tcode> }| ).
            ENDLOOP.

            APPEND LINES OF VALUE yif_ticksys_ticketing_system=>ticket_id_list( FOR GROUPS _grp OF _result IN results
                                                                                WHERE (     parent IN me->reader->issue_key_parent_rng "#EC CI_SORTSEQ
                                                                                        AND name    = 'key' )
                                                                                GROUP BY _result-value
                                                                                ( CONV #( _grp ) ) )
                   TO new_cache-tickets.

            INSERT new_cache INTO TABLE me->tcode_ticket_cache ASSIGNING <cache>.
          ENDIF.

          APPEND LINES OF <cache>-tickets TO tickets.
        ENDLOOP.

        SORT tickets.
        DELETE ADJACENT DUPLICATES FROM tickets.

      CATCH ycx_ticksys_ticketing_system INTO DATA(ts_error).
        RAISE EXCEPTION ts_error.
      CATCH cx_root INTO DATA(diaper).
        RAISE EXCEPTION NEW ycx_ticksys_ticketing_system( previous = diaper ).
    ENDTRY.
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
ENDCLASS.
