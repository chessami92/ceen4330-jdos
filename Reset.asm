;Reset location of the 8086
org 0fff0h
   nop
   jmp pJdosInit

org 0fff6h
defaultInterrupt:
   iret
