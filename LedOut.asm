;inputs:    ax - lower 16 bits of pattern
;           bl - lower nibble is most significant 4 bits
;outputs:   pattern displayed to LEDs
pOutputToLeds proc near
   push cx,ds

   mov cx,keyboardSegment
   mov ds,cx
   
   ;begin writing at first byte location
   mov B[keyboardCommand],10010000b

   ;data for LEDs
   mov [keyboardData],al
   mov [keyboardData],ah
   mov [keyboardData],bl
   mov B[keyboardData],00h
   
   pop ds,cx
   ret
pOutputToLeds endp
