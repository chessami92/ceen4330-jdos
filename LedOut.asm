;inputs:    ax - lower 16 bits of pattern
;           bl - lower nibble is most significant 4 bits
;outputs:   pattern displayed to LEDs
pOutputToLeds proc near
   push ds

   mov bx,keyboardSegment
   mov ds,bx

   ;begin writing at first byte location
   mov B[keyboardCommand],10010000b

   ;data for LEDs
   mov B[keyboardData],al
   mov B[keyboardData],ah
   mov B[keyboardData],bl

   pop ds

   ret
pOutputToLeds endp
