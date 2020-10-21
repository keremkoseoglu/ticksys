*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 21.10.2020 at 10:01:32
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_TICSY.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_TICSY               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_TICSY               .
CONTROLS: TCTRL_YTTICKSYS_TICSY
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_TICSY               .
TABLES: YTTICKSYS_TICSY                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
