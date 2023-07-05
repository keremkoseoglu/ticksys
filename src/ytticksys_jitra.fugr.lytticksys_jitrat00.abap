*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JITRA.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JITRA               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JITRA               .
CONTROLS: TCTRL_YTTICKSYS_JITRA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JITRA               .
TABLES: YTTICKSYS_JITRA                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
