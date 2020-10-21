*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 21.10.2020 at 10:12:57
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: YTTICKSYS_JIDEF.................................*
DATA:  BEGIN OF STATUS_YTTICKSYS_JIDEF               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_YTTICKSYS_JIDEF               .
CONTROLS: TCTRL_YTTICKSYS_JIDEF
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *YTTICKSYS_JIDEF               .
TABLES: YTTICKSYS_JIDEF                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
