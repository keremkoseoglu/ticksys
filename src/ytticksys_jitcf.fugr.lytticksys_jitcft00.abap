*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JITCF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JITCF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JITCF               .
CONTROLS: TCTRL_YTTICKSYS_JITCF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JITCF               .
TABLES: YTTICKSYS_JITCF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
