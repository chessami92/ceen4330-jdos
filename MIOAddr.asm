keyboardPointers EQU 0FFF0h   ;meta-data for queue
keyboardQueue EQU 0FFF1h      ;actual ascii key entry queue

stackBegin EQU 0FE60h         ;top of stack - goes into SP, SS = 0

keyboardSegment EQU 1000h     ;address of 8279
keyboardData EQU 0000h        ;data port of 8279
keyboardCommand EQU 0002h     ;command port of 8279

lcdSegment EQU 2000h          ;address of LCD
lcdOffset EQU 0000h           ;offset of LCD
