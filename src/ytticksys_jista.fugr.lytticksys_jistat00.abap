*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JISTA.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JISTA               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JISTA               .
CONTROLS: TCTRL_YTTICKSYS_JISTA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JISTA               .
TABLES: YTTICKSYS_JISTA                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
