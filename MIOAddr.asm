stackBegin EQU 0ebe0h         ;top of stack - goes into SP, SS = 0

;rows wrap around in memory. Multiply row * 20 to get location in memory. 
currentLcdCursor EQU 0ebech   ;where the cursor is on the LCD - 0 through 79 (correct line wrapping)
cursorColumn EQU 0ebedh       ;location in RAM where next character will be printed
cursorRow EQU 0ebeeh
currentPrintRow EQU 0ebefh    ;location in RAM of starting character on LCD - 4 rows are displayed
screenData EQU 0ebf0h         ;256 lines of 20 characters, or 1400h bytes of video data

keyboardPointers EQU 0fff0h   ;meta-data for queue
keyboardQueue EQU 0fff1h      ;actual ascii key entry queue

ramSegment EQU 0000h          ;where RAM is located

keyboardSegment EQU 1000h     ;address of 8279
keyboardData EQU 0000h        ;data port of 8279
keyboardCommand EQU 0002h     ;command port of 8279

lcdSegment EQU 2000h          ;address of LCD
lcdOffset EQU 0000h           ;offset of LCD

intControllerSegment EQU 3000h;address of interrupt controller
intCommand1 EQU 0000h         ;offset for commands
intCommand2 EQU 0002h         ;offset for second type of command

clockSegment EQU 4000h        ;address of real time clock
year EQU 0ffeh                ;BCD of year, 00-99
month EQU 0ffch               ;BCD of month, 1-12
date EQU 0ffah                ;BCD of date, 1-31
day EQU 0ff8h                 ;day of week, 1-7
hour EQU 0ff6h                ;hour of the day, 0-23
minute EQU 0ff4h              ;minute of hour, 0-59
second EQU 0ff2h              ;secodn of minute, 0-59
control EQU 0ff0h             ;control register
century EQU 0feeh             ;century, 19 or 20

romSegment EQU 0f000h         ;where ROM is located

;each mapping in this table takes 5 bytes: 1 for which interrupt,
;4 for the CS and IP of the interrupt
interruptTable:
   db 09h,           ;keyboard hardware
   dw int09h, 0f000h,
   db 10h            ;print screen
   dw int10h, 0f000h
   db 16h,           ;keyboard service
   dw int16h, 0f000h,
   db 1ah,           ;real time clock
   dw int1ah, 0f000h,
   db 21h,           ;JDOS function calls
   dw int21h, 0f000h
endInterruptTable:
