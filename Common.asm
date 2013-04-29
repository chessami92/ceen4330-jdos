;inputs:    al
;outputs:   al, converted to uppercase
;calls:     none
pUpperCaseAl proc near
   cmp al,61h
   jb complete
   cmp al,7ah
   ja complete
   sub al,20h
   
complete:
   ret
pUpperCaseAl endp

;inputs:    register/memory of hex to convert to ascii
;outputs:   register/memory converted to ascii
;calls:     none
mHexToAscii macro
   add #1,30h
   cmp #1,39h
   jbe >m1
   add #1,7h
m1:
#em

;inputs:    register/memory to conver to printable ascii range
;outputs:   same register/memory, safe to print
;calls:     none
mConvertToPrintable macro
   cmp #1,20h
   jae >m1
   mov #1,'.'

m1:
   cmp #1,7eh
   jbe >m2
   mov #1,'.'

m2:
#em

;inputs:    memory/register/immediate - character to print
;outputs:   none, character printed to screen
;calls:     int 10h - print character
mOutputCharacter macro
   push ax,dx

   mov dl,#1
   mov ah,09h
   int 10h
   
   pop dx,ax
#em

;inputs:    none
;outputs:   none, reuturns after 10us
;calls:     none
pDelay10us proc near
   ;total of 51 ccs
   ;initial call takes 19ccs
   nop               ;3ccs
   nop               ;3ccs
   nop               ;3ccs
   nop               ;3ccs

   ret               ;20ccs
pDelay10us endp

msDelay EQU 73
;inputs:    none
;outputs:   none, continues after 1ms
;calls:     pDelay10us
pDelay1ms proc near
   ;total of 5000 ccs
   ;initial call takes 19ccs
   push cx           ;11ccs

   mov cx,msDelay    ;4ccs
tenUsDelay:
   call pDelay10us   ;51ccs
   loop tenUsDelay   ;17/5ccs

   pop cx            ;8ccs
   ret               ;20ccs
pDelay1ms endp

;inputs:    cx - number of ms to wait
;outputs:   none, returns after cx ms
;calls:     pDelay1ms
pDelayMs proc near
   push cx

delayCxMs:
   call pDelay1ms
   loop delayCxMs

   pop cx
   ret
delayMs endp

;inputs:    none
;outputs:   none, returns after 40us
;calls:     pDelay10us
mDelay40us macro
   call pDelay10us
   call pDelay10us
   call pDelay10us
   call pDelay10us
#em

;inputs:    word memory/register/immediate - how many ms to delay
;outputs:   none, returns after number ms
;calls:     pDelayMs
mDelayMs macro
   push cx
   mov cx,#1
   call pDelayMs
   pop cx
#em

;inputs:    bx - lower 16 bits of pattern
;           al - lower nibble is most significant 4 bits
;outputs:   pattern displayed to LEDs
;calls:     none
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
