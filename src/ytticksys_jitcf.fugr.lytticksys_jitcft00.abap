*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 14.11.2020 at 13:16:33
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JITCF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JITCF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JITCF               .
CONTROLS: TCTRL_YTTICKSYS_JITCF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JITCF               .
TABLES: YTTICKSYS_JITCF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
