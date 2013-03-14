stackBegin EQU 0fd60h         ;top of stack - goes into SP, SS = 0

;rows wrap around in memory. Multiply row * 20 to get location in memory. 
cursorColumn EQU 0fd6ch       ;location in RAM where next character will be printed
cursorRow EQU 0fd6dh
currentPrintRow EQU 0fd6eh    ;location in RAM of starting character on LCD - 4 rows are displayed
lastRowPrinted EQU 0fd6fh     ;last row that has been used - next row is oldest row (will be overwritten next)
screenData EQU 0fd70h         ;32 lines of 20 character, or 280h bytes of video data

keyboardPointers EQU 0fff0h   ;meta-data for queue
keyboardQueue EQU 0fff1h      ;actual ascii key entry queue

keyboardSegment EQU 1000h     ;address of 8279
keyboardData EQU 0000h        ;data port of 8279
keyboardCommand EQU 0002h     ;command port of 8279

lcdSegment EQU 2000h          ;address of LCD
lcdOffset EQU 0000h           ;offset of LCD

intControllerSegment EQU 3000h;address of interrupt controller
intCommand1 EQU 0000h         ;offset for commands
intCommand2 EQU 0002h         ;offset for second type of command
