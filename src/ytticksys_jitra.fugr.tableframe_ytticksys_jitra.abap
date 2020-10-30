*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_YTTICKSYS_JITRA
*   generation date: 30.10.2020 at 18:36:59
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_YTTICKSYS_JITRA    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
