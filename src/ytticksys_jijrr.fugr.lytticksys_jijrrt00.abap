*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JIJRR.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JIJRR               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JIJRR               .
CONTROLS: TCTRL_YTTICKSYS_JIJRR
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JIJRR               .
TABLES: YTTICKSYS_JIJRR                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
