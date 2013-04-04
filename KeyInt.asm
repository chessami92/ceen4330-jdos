;Keyboard service requests

;inputs:    none
;outputs:   bh - head of queue
;           bl - tail of queue
pGetKeyboardPointers proc near
   push ds
   
   mov ds,ramSegment
   mov bl,[keyboardPointers]
   mov bh,bl
   and bx,0f00fh     ;clear duplicate nibbles
   shr bh,1          ;bh - head, bl - tail
   shr bh,1
   shr bh,1
   shr bh,1
   
   pop ds
   ret
pGetKeyboardPointers endp

;inputs:    bh - head of queue
;           bl - tail of queue
;outputs:   none, stored back in memory in proper format
pSetKeyboardPointers proc near
   push bx,ds
   
   cmp bh,0fh        ;see if pointing to end of array
   jne ValidNewBh
   xor bh,bh         ;wrap around to beginning of array
   
validNewBh:
   cmp bl,0fh        ;see if pointing to end of array
   jne validNewBl
   xor bl,bl         ;wrap around to beginning of array
   
validNewBl:
   ;if head now equals tail, the queue is full, don't update pointers
   cmp bh,bl
   je keyboardQueueFull
   
   mov ds,ramSegment
   shl bh,1          ;re-construct pointer byte
   shl bh,1
   shl bh,1
   shl bh,1
   or bl,bh
   mov [keyboardPointers],bl
   
keyboardQueueFull:
   pop ds,bx
   ret
pSetKeyboardPointers endp

;inputs:    dl - the new character
;outputs:   queue is updated with new character if possible
mInsertIfNotFull macro
   push bx,ds
   
   mov ds,ramSegment ;change to RAM segment

   call pGetKeyboardPointers
   ;head always points to open location
   push bx
   mov bl,bh
   xor bh,bh
   mov [keyboardQueue + bx],dl
   pop bx

   inc bh            ;point to next location
   call pSetKeyboardPointers
   
   pop ds,bx
#em

scanAsciiTable db 08h, ')^_>~~~&*BA(~~~$%DC^~~~!@FE#~~~', 08h, '0^_>~~~78ba9~~~45dc6~~~12fe3~~~'
;called by hardware when character is available
;inputs:    none
;outputs:   queue is updated with new character
int09h proc far
   push bx,dx,ds

   mov ds,keyboardSegment

   mov B[keyboardCommand],01000000b ;setup to read 8279

   xor bx,bx
   mov bl,[keyboardData]
   mov B[keyboardCommand],11100000b ;end the 8279 interrupt request

   shl bx,1          ;remove unused bit between scan code and shift bit
   shl bx,1
   shl bl,1
   shr bx,1
   shr bx,1
   shr bx,1
   
checkControlA:
   cmp bl,00101011b  ;lower case ^A
   jne checkControlC
   mov dl,0ah
   jmp insertNewCharacter
   
checkControlC:
   cmp bl,00110011b  ;lower case ^C
   jne noControlCharacters
   mov ah,00h        ;return to main program
   int 21h

noControlCharacters:
   and bl,3fh        ;clear control bit, then convert to ASCII
   mov dl,cs:[offset scanAsciiTable + bx]

insertNewCharacter:
   mInsertIfNotFull

   pop ds,dx,bx
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
   mov ah,00h        ;restore value of ah
   jmp keyboardInterruptComplete

checkKeyboardInitialization:
   cmp ah,04h
   jne keyboardInterruptComplete
   call pInitializeKeyboard
   
keyboardInterruptComplete:
   iret
int16h endp

;inputs:    none
;outputs:   al - ASCII character
pReadCharacter proc near
   push bx,ds

   mov ds,ramSegment

waitForCharacter:
   sti
   mDelayMs 50       ;allow keyboard interrupts for a while
   cli
   call pGetKeyboardPointers
   inc bl            ;point to next character
   mov ax,bx
   call pSetKeyboardPointers
   call pGetKeyboardPointers
   cmp ax,bx         ;pSetKeyboardPointers didn't work, queue must be empty
   jne waitForCharacter
   
   xor bh,bh         ;put character in al
   mov al,[keyboardQueue + bx]
   
   pop ds,bx
   ret               ;got character, return to caller
pReadCharacter endp

;inputs:    none
;outputs:   none, 8279 initialized
pInitializeKeyboard proc near
   push ax,ds

   mov ds,keyboardSegment

   mov B[keyboardCommand],00000001b ;set to decoded scan keyboard
   mov B[keyboardCommand],00111001b ;set to 25 prescaler to get 100kHz clock
   mov B[keyboardCommand],10100000b ;do not mast display nibbles
   mov B[keyboardCommand],11000001b ;clear FIFO and RAM
  
   mov ds,ramSegment ;set up head and tail pointer for RAM key queue
   mov B[keyboardPointers],0dh

   pop ds,ax
   ret
pInitializeKeyboard endp
