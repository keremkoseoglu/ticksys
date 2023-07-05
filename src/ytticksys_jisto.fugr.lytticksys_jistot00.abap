*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JISTO.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JISTO               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JISTO               .
CONTROLS: TCTRL_YTTICKSYS_JISTO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JISTO               .
TABLES: YTTICKSYS_JISTO                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
