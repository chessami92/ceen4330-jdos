;inputs:    none
;outputs:   pattern displayed to LEDs
pOutputToLeds proc near
   push ds

   mov bx,keyboardSegment
   mov ds,bx

   ;begin writing at first byte location
   mov B[keyboardCommand],10010000b

   ;data for LEDs
   mov B[keyboardData],0AAh
   mov B[keyboardData],0AAh
   mov B[keyboardData],0AAh

   pop ds

   ret
pOutputToLeds endp
