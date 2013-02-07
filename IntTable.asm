org 0fbf0
interruptTable:
   dw 16 DUP (defaultInterrupt, 0f000h)
   dw 16 DUP (defaultInterrupt, 0f000h)

org 0fff6h
defaultInterrupt:
   iret
