;inputs:    bx - lower 16 bits of pattern
;           al - lower nibble is most significant 4 bits
;outputs:   pattern displayed to LEDs
pOutputToLeds proc near
   push ds

   mov ds,keyboardSegment
   
   ;begin writing at first byte location
   mov B[keyboardCommand],10010000b

   ;data for LEDs
   mov [keyboardData],bl
   mov [keyboardData],bh
   mov [keyboardData],al
   mov B[keyboardData],00h
   
   pop ds
   ret
pOutputToLeds endp
