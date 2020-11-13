*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 13.11.2020 at 17:23:39
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JITIF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JITIF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JITIF               .
CONTROLS: TCTRL_YTTICKSYS_JITIF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JITIF               .
TABLES: YTTICKSYS_JITIF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
