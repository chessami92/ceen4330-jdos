;Keyboard service requests
keyboardSegment EQU 1000h
keyboardData EQU 0002h
keyboardCommand EQU 0004h

scanAsciiTable db '0123456789ABCDEF'
;called by hardware when character is available
;inputs:    none
;outputs:   ah - key scan code
;           al - ASCII character
int09h proc far
   mov ah,[keyboardData]
   mov al,ah
   mov bx,offset scanAsciiTable
   xlat              ;convert al to ASCII

   iret
int09h endp

;called by software to request key or initialize keyboard
;inputs:    ah - function code
;outputs:   dependent on function code
int16h proc far
checkReadCharacter:
   cmp ah,00h
   jne checkKeyboardInitialization
   call pReadCharacter
   jmp keyboardInterruptComplete

checkKeyboardInitialization:
   cmp ah,04h
   jne keyboardInterruptComplete
   call pInitializeKeyboard
   
keyboardInterruptComplete:
   iret
int10h endp

;inputs:    none
;outputs:   ah - key scan code
;           al - ASCII character
pReadCharacter proc near
   xor ax,ax
   
waitForKeyboardInterrupt:
   sti               ;allow interrupts for one instruction, avoids
   cli               ;possible issue when multiple characters waiting
   cmp ax,0          ;once keyboard interrupt occurs, ax will not be 0
   je waitForKeyboardInterrupt
   
   ret               ;got character, return to caller
pReadCharacter endp

;inputs:    none
;outputs:   none, 8279 initialized
pInitializeKeyboard proc near
   push ds
   mov ds,keyboardSegment

   mov B[keyboardCommand],00000001b ;set to decoded scan keyboard
   mov B[keyboardCommand],00111001b ;set to 25 prescaler to get 100kHz clock
   mov B[keyboardCommand],01000000b ;setup to read character queue

   pop ds
   ret
pInitializeKeyboard endp
