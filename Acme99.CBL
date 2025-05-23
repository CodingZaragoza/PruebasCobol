       IDENTIFICATION DIVISION.
       PROGRAM-ID.  ACME99.
       AUTHOR. Michael Coughlan.
      * CS431399R-EXAM.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
               SELECT ORDER-FILE ASSIGN TO "ORDERS.DAT"
                      ORGANIZATION IS LINE SEQUENTIAL.
       
               SELECT STOCK-FILE ASSIGN TO "STOCK.DAT"
                               ORGANIZATION IS RELATIVE
                               ACCESS MODE IS DYNAMIC
                               RELATIVE KEY IS STOCK-REC-POINTER-WB
                               FILE STATUS IS STOCK-STATUS-WB.
       
               SELECT MANF-FILE ASSIGN TO "MANF.DAT"
                               ORGANIZATION IS INDEXED
                               ACCESS MODE IS RANDOM
                               RECORD KEY IS MANF-CODE-FC
                               ALTERNATE RECORD KEY IS MANF-NAME-FC
                                        WITH DUPLICATES
                               FILE STATUS IS MANF-STATUS-WB.
       
       
       
       DATA DIVISION.
       FILE SECTION.
       FD  ORDER-FILE.
       01  ORDER-REC-FA.
           02 ITEM-DESC-FA                 PIC X(30).
           02 MANF-NAME-FA                 PIC X(30).
           02 QTY-REQUIRED-FA              PIC 9(6).
           02 COST-OF-ITEMS-FA             PIC 9(5)V99.
           02 POSTAGE-FA                   PIC 99V99.
       
       FD  STOCK-FILE.
       01  STOCK-REC-FB.
           02 STOCK-NUM-FB                 PIC 9(5).
           02 MANF-CODE-FB                 PIC X(4).
           02 ITEM-DESC-FB                 PIC X(30).
           02 QTY-IN-STOCK-FB              PIC 9(6).
           02 REORDER-LEVEL-FB             PIC 999.
           02 REORDER-QTY-FB               PIC 9(6).
           02 ITEM-COST-FB                 PIC 9(5).
           02 ITEM-WEIGHT-FB               PIC 9(5).
           02 ON-ORDER-FB                  PIC X.
              88 NOT-ON-ORDER              VALUE "N".
              88 ON-ORDER                  VALUE "Y".
       
       FD  MANF-FILE.
       01  MANF-REC-FC.
           02 MANF-CODE-FC                 PIC X(4).
           02 MANF-NAME-FC                 PIC X(30).
           02 MANF-ADDRESS-FC              PIC X(70).
       
       
       
       
       WORKING-STORAGE SECTION.
       01  CALL-ITEMS-WA.
           02 POST-CHARGE-WA               PIC 99V99.
           02 POST-NUM-WA                  PIC 99.
       
       01  FILE-DATA-WB.
           02 STOCK-REC-POINTER-WB         PIC 9(5).
           02 STOCK-STATUS-WB              PIC XX.
           02 MANF-STATUS-WB               PIC XX.
           02 FILLER                       PIC 9 VALUE 0.
              88 END-OF-FILE               VALUE 1.
       
       01  UNSTRING-DATA-WC.
           02 UNSTRING-POINTER-WC          PIC 99.
              88 END-OF-ADDRESS            VALUE 71.
           02 HOLD-STRING-WC               PIC X(10).
           02 COUNTY-WC                    PIC X(9).
              88      NORTHERN-COUNTY
                  VALUE "ANTRIM", "ARMAGH", "DERRY", "DOWN",
                                     "FERMANAGH", "TYRONE".
           02 COUNTRY-WC                   PIC X(10).
              88 EEC-COUNTRY
                 VALUE   "AUSTRIA", "BELGIUM", "DENMARK", "ENGLAND", "FINLAND", 
                         "FRANCE", "GERMANY", "GREECE", "IRELAND", "ITALY", 
                         "LUXEMBOURG", "PORTUGAL", "SCOTLAND", "SPAIN",
                         "SWEDEN", "WALES".
              88 IRELAND                   VALUE "IRELAND".
       
           02 COUNTRY-FLAGS-WC             PIC 9.
              88 OTHER-EEC                 VALUE 1.
              88 REPUBLIC                  VALUE 0.
       
       01 POSTAGE-DATA-WD.
          02 TOTAL-WEIGHT-WD                         PIC 9(5).
             88 OVER-WEIGHT             VALUE 50001 THRU 99999.
       
       
       
       PROCEDURE DIVISION.
       CREATE-REORDER-FILE.
          OPEN I-O STOCK-FILE.
          OPEN INPUT MANF-FILE.
          OPEN OUTPUT ORDER-FILE.
          READ STOCK-FILE NEXT RECORD
                 AT END SET END-OF-FILE TO TRUE
          END-READ.
          PERFORM UNTIL END-OF-FILE
             IF (QTY-IN-STOCK-FB NOT GREATER THAN  REORDER-LEVEL-FB)
                                   AND   (NOT-ON-ORDER)
                    PERFORM CREATE-REORDER-RECORD
                    PERFORM UPDATE-STOCK-RECORD
             END-IF
             READ STOCK-FILE NEXT RECORD
                      AT END SET END-OF-FILE TO TRUE
             END-READ
          END-PERFORM.
          CLOSE STOCK-FILE, MANF-FILE, ORDER-FILE.
          STOP RUN.
       
       CREATE-REORDER-RECORD.
          MOVE MANF-CODE-FB TO MANF-CODE-FC.
          READ MANF-FILE
               KEY IS MANF-CODE-FC
               INVALID KEY DISPLAY "CRR MANF STATUS = "
                                   MANF-STATUS-WB "CODE = " MANF-CODE-FC
          END-READ.
          PERFORM EXTRACT-ADDRESS-ITEMS.
       
          MOVE ZEROS TO POSTAGE-FA, COST-OF-ITEMS-FA.
          IF EEC-COUNTRY
             PERFORM GET-POSTAGE
             MULTIPLY ITEM-COST-FB BY REORDER-QTY-FB
       			GIVING	COST-OF-ITEMS-FA
             MOVE POST-CHARGE-WA TO POSTAGE-FA
          END-IF.
       
          MOVE ITEM-DESC-FB TO ITEM-DESC-FA.
          MOVE MANF-NAME-FC TO MANF-NAME-FA.
          MOVE REORDER-QTY-FB TO QTY-REQUIRED-FA.
          WRITE ORDER-REC-FA.
       
       GET-POSTAGE.
          IF IRELAND AND NOT NORTHERN-COUNTY
       		 SET REPUBLIC TO TRUE
        	  ELSE
       		 SET OTHER-EEC TO TRUE
          END-IF.
          MULTIPLY ITEM-WEIGHT-FB BY REORDER-QTY-FB
                   GIVING TOTAL-WEIGHT-WD
                   ON SIZE ERROR  MOVE 99999 TO TOTAL-WEIGHT-WD.
       	
          EVALUATE TOTAL-WEIGHT-WD ALSO REPUBLIC ALSO OTHER-EEC
            WHEN  1 THRU 500       ALSO TRUE     ALSO FALSE MOVE 1 TO POST-NUM-WA
            WHEN  1 THRU 500       ALSO FALSE    ALSO TRUE  MOVE 2 TO POST-NUM-WA
            WHEN  501 THRU 1000    ALSO TRUE     ALSO FALSE MOVE 3 TO POST-NUM-WA
            WHEN  501 THRU 1000    ALSO FALSE    ALSO TRUE  MOVE 4 TO POST-NUM-WA
            WHEN  1001 THRU 3000   ALSO TRUE     ALSO FALSE MOVE 5 TO POST-NUM-WA
            WHEN  1001 THRU 3000   ALSO FALSE    ALSO TRUE  MOVE 6 TO POST-NUM-WA
            WHEN  3001 THRU 5000   ALSO TRUE     ALSO FALSE MOVE 7 TO POST-NUM-WA
            WHEN  3001 THRU 5000   ALSO FALSE    ALSO TRUE  MOVE 8 TO POST-NUM-WA
            WHEN  5001 THRU 10000  ALSO TRUE     ALSO FALSE MOVE 9 TO POST-NUM-WA
            WHEN  5001 THRU 10000  ALSO FALSE    ALSO TRUE  MOVE 10 TO POST-NUM-WA
            WHEN  10001 THRU 50000 ALSO TRUE     ALSO FALSE MOVE 11 TO POST-NUM-WA
            WHEN  10001 THRU 50000 ALSO FALSE    ALSO TRUE  MOVE 12 TO POST-NUM-WA
            WHEN  50001 THRU 99999 ALSO ANY      ALSO ANY   MOVE ZEROS
                                                            TO POST-CHARGE-WA
            WHEN OTHER DISPLAY "EVALUATE WRONG:- WEIGHT =  " TOTAL-WEIGHT-WD
       				" COUNTRY FLAG = " COUNTRY-FLAGS-WC
          END-EVALUATE.
          IF NOT OVER-WEIGHT
             CALL "POSTAGE-RATE"
                  USING BY CONTENT POST-NUM-WA
                  BY REFERENCE POST-CHARGE-WA
          END-IF.
       
       
       
       UPDATE-STOCK-RECORD.
          MOVE "Y" TO ON-ORDER-FB.
          REWRITE STOCK-REC-FB
                  INVALID KEY DISPLAY "STOCK REWRITE STATUS = " STOCK-STATUS-WB
          END-REWRITE.
       
       		
       
       EXTRACT-ADDRESS-ITEMS.
          MOVE 1 TO UNSTRING-POINTER-WC.
          PERFORM UNTIL END-OF-ADDRESS
                  MOVE HOLD-STRING-WC TO COUNTY-WC
                  UNSTRING MANF-ADDRESS-FC DELIMITED BY ","
                           INTO HOLD-STRING-WC
                           WITH POINTER UNSTRING-POINTER-WC
          END-PERFORM.
          MOVE HOLD-STRING-WC TO COUNTRY-WC.
       
      * debugging displays
          DISPLAY "COUNTY = "  COUNTY-WC.
          DISPLAY "COUNTRY = " COUNTRY-WC.
       