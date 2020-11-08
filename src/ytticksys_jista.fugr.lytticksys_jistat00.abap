*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 08.11.2020 at 16:44:30
*   view maintenance generator version: #001407#
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
