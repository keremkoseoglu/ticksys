*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_YTTICKSYS_JITCF
*   generation date: 14.11.2020 at 13:16:33
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_YTTICKSYS_JITCF    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
