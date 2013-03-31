;Keyboard service requests

;inputs:    dl - the new character
;outputs:   queue is updated with new character if possible
mInsertIfNotFull macro
   push bx,cx,ds
   
   mov ds,0000h      ;change to RAM segment

   mov bl,[keyboardPointers]
   mov bh,bl
   and bx,0f00fh     ;clear duplicate nibbles
   mov cl,4
   shr bh,cl         ;bh - head, bl - tail

   ;head always points to open location
   push bx
   mov bl,bh
   xor bh,bh
   mov [bx + keyboardQueue],dl
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
   pop ds,cx,bx
#em

scanAsciiTable db 08h, ')^_>~~~&*AB(~~~$%DC^~~~!@FE#~~~', 08h, '0^_>~~~78ba9~~~45dc6~~~12fe3~~~'
;called by hardware when character is available
;inputs:    none
;outputs:   queue is updated with new character
int09h proc far
   push bx,dx,ds

   mov ds,keyboardSegment

   mov B[keyboardCommand],01000000b ;setup to read 8279

   xor bx,bx
   mov bl,[keyboardData]

   shl bx,1          ;remove unused bit between scan code and shift bit
   shl bx,1
   shl bl,1
   shr bx,1
   shr bx,1

   and bl,3fh        ;TODO: add in logic to detect control c, notify Jdos
   mov dl,cs:[offset scanAsciiTable + bx]

   mov B[keyboardCommand],11100000b ;end the 8279 interrupt request

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
   push ds

   mov ds,keyboardSegment
   
   ;TODO: read from character queue in RAM
   
   pop ds
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
  
   mov ds,0000h      ;set up head and tail pointer for RAM key queue
   mov B[keyboardQueue],0Eh

   pop ds,ax
   ret
pInitializeKeyboard endp
