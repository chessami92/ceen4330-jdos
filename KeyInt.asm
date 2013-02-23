;Keyboard service requests

;inputs:    al - the new character
;outputs:   queue is updated with new character if possible
;           modifies ds to be the RAM segment
mInsertIfNotFull macro
   push cx
   
   xor bx,bx         ;change to RAM segment
   mov ds,bx

   mov bl,[keyboardPointers]
   mov bh,bl
   and bx,0f00fh     ;clear duplicate nibbles
   mov cl,4
   shr bh,cl         ;bh - head, bl - tail

   ;head always points to open location
   push bx
   mov bl,bh
   xor bh,bh
   mov [bx + keyboardQueue],al
   pop bx

   inc bh
   cmp bh,0fh        ;see if pointing to end of array
   jne validNewBh
   xor bh,bh         ;wrap around to beginning of array

validNewBh:
   ;if head now equals tail, the queue is full, don't update pointers
   cmp bh,bl
   je characterInsertComplete

   shl bh,cl         ;re-construct pointer byte
   or bl,bh
   mov [keyboardPointers],bl
   
characterInsertComplete:
   pop cx
#em

scanAsciiTable db '0123456789ABCDEF'
;called by hardware when character is available
;inputs:    none
;outputs:   queue is updated with new character
int09h proc far
   push bx,ds
   mov bx,keyboardSegment
   mov ds,bx

   mov B[keyboardCommand],01000000b ;setup to read 8279

   xor bx,bx
   mov bl,[keyboardData]
   mov al,cs:[bx + offset scanAsciiTable]

   mov B[keyboardCommand],11100000b ;end the 8279 interrupt request

   mInsertIfNotFull

   pop ds,bx
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
int16h endp

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
   push ax,ds
   mov ds,keyboardSegment

   mov B[keyboardCommand],00000001b ;set to decoded scan keyboard
   mov B[keyboardCommand],00111001b ;set to 25 prescaler to get 100kHz clock
   mov B[keyboardCommand],01000000b ;setup to read character queue
  
   xor ax,ax         ;set up head and tail pointer for queue
   mov ds,ax
   mov B[keyboardQueue],0Eh

   pop ds,ax
   ret
pInitializeKeyboard endp
