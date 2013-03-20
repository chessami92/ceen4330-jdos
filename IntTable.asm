;each mapping in this table takes 5 bytes: 1 for which interrupt,
;4 for the CS and IP of the interrupt
interruptTable:
   db 09h,           ;keyboard hardware
   dw int09h, 0f000h,
   db 10h            ;print screen
   dw int10h, 0f000h
   db 12h,           ;memory check
   dw defaultInterrupt, 0f000h,
   db 16h,           ;keyboard service
   dw int16h, 0f000h,
   db 1Ah,           ;real time clock
   dw defaultInterrupt, 0f000h,
   db 21h,           ;JDOS function calls
   dw int21h, 0f000h
endInterruptTable:
