*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_YTTICKSYS_JITCF
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_YTTICKSYS_JITCF    .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
