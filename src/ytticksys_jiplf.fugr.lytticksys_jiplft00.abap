*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JIPLF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JIPLF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JIPLF               .
CONTROLS: TCTRL_YTTICKSYS_JIPLF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JIPLF               .
TABLES: YTTICKSYS_JIPLF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
