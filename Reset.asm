;Reset location of the 8086
org 0fff0h
   cli               ;make sure no interrupts while initializing
   jmp 0f000h:offset pJdosInit

org 0fff6h
defaultInterrupt:
   iret
