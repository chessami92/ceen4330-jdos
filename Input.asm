;inputs:    dl - lower nibble is highest allowed hex number
;           dh - msb set if user is allowed to press delete
;              second msb set if the character should be echoed
;outputs:   al - number, 00h-0fh inputted by user
;              msb is set if user hit space
;              second msb is set if user hit enter
;              third msb is set if user hit backspace
pInputOneHex proc
   push dx,ax

attemptInputCharacter:
   mov ah,07h
   int 21h

checkPressedSpace:
   cmp al,' '
   jne checkPressedEnter
   mov al,80h
   jmp doneInputOneHex
checkPressedEnter:
   cmp al,0ah
   jne checkPressedBackspace
   mov al,40h
   jmp doneInputOneHex
checkPressedBackspace:
   cmp al,08h
   jne normalInputHex
   rol dh,1
   ror dh,1
   jnc attemptInputCharacter
   mOutputCharacter al
   mov al,20h
   jmp doneInputOneHex
   
normalInputHex:
   call pUpperCaseAl
   cmp al,'0'        ;check for 0-9
   jb attemptInputCharacter
   cmp al,'9'
   ja checkLetters
   jmp validInput
  
checkLetters:
   cmp al,'A'        ;check for A-F
   jb attemptInputCharacter
   cmp al,'F'
   ja attemptInputCharacter
   
   sub al,07h        ;adjust letter to hex range

validInput:
   and al,0fh        ;clear upper nibble
   cmp al,dl
   ja attemptInputCharacter
   
   shl dh,1
   shl dh,1
   jnc doneInputOneHex
   mov dl,al
   mHexToAscii dl
   mOutputCharacter dl;print out the valid hex number
   
doneInputOneHex:
   pop dx            ;restore ah, don't overwrite al
   mov ah,dh
   pop dx
   ret
pInputOneHex endp
