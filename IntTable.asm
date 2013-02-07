org 0fbf0

interruptTable dw defaultInterrupt, 0f000h
   dw 14 DUP (defaultInterrupt, 0f000h),
   dw int10h, 0f000h
   dw 16 DUP (defaultInterrupt, 0f000h)
   dw int21h, 0f000h
   dw 223 DUP (defaultInterrupt, 0f000h)
