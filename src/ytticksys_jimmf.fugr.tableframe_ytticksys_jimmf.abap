*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_YTTICKSYS_JIMMF
*   generation date: 17.01.2022 at 10:24:41
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_YTTICKSYS_JIMMF    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
