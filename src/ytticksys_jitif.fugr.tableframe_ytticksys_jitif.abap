*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_YTTICKSYS_JITIF
*   generation date: 13.11.2020 at 17:23:39
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_YTTICKSYS_JITIF    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
