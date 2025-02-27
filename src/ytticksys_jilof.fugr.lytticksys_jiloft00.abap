*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JILOF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JILOF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JILOF               .
CONTROLS: TCTRL_YTTICKSYS_JILOF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JILOF               .
TABLES: YTTICKSYS_JILOF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
