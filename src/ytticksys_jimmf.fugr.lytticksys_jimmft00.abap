*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JIMMF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JIMMF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JIMMF               .
CONTROLS: TCTRL_YTTICKSYS_JIMMF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JIMMF               .
TABLES: YTTICKSYS_JIMMF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
