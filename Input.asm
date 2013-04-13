;inputs:    dl - lower nibble is highest allowed hex number
;           dh - msb set if normal characters should be echoed
;              second msb set if user is allowed to press enter
;              third msb set if user is allowed to press backspace
;              fourth msb set if user not allowed to press normal characters (0-f)
;outputs:   al - number, 00h-0fh inputted by user
;           ah - msb is set if user hit space
;              second msb is set if user hit enter
;              third msb is set if user hit backspace
;calls:     int 21h - input without echo, int 10h - print character function
pInputOneHex proc
   push cx,dx

attemptInputCharacter:
   mov ah,07h
   int 21h

checkPressedSpace:
   cmp al,' '
   jne checkPressedEnter
   mov ah,80h        ;set proper return code for pressing space
   jmp doneInputOneHex
checkPressedEnter:
   cmp al,0ah
   jne checkPressedBackspace
   push dx
   mov cl,2
   shl dh,cl         ;see if pressing return is allowed
   pop dx
   jnc attemptInputCharacter
   mov ah,40h        ;set proper return code for pressing enter
   jmp doneInputOneHex
checkPressedBackspace:
   cmp al,08h
   jne normalInputHex
   push dx
   mov cl,3
   shl dh,cl         ;see if pressing backspace is allowed
   pop dx
   jnc attemptInputCharacter
   mOutputCharacter al
   mov ah,20h        ;set proper return code for pressing backspace
   jmp doneInputOneHex
   
normalInputHex:
   push dx
   mov cl,4
   shl dh,cl         ;check if normal characters (0-f) are allowed
   pop dx
   jc attemptInputCharacter
   
   call pUpperCaseAl ;convert to uper case if necessary
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
   cmp al,dl         ;make sure that inputted character is not greater than max allowed character
   ja attemptInputCharacter
   
   shl dh,1          ;see if character should be echoed
   jnc doneInputOneHex
   mov dl,al
   mHexToAscii dl
   mOutputCharacter dl;print out the valid hex number
   
doneInputOneHex:
   pop dx,cx
   ret
pInputOneHex endp

;inputs:    cl - number of characters to input
;           ch - the maximum number allowed (0-f)
;outputs:   bx - the inputted characters in hex format
;              characters echoed to screen
;           cf - set if user hit space to exit
;calls:     pInputOneHex
pInputManyHex proc near
   push ax,cx,dx
   
   xor bx,bx
   mov dl,ch         ;for pInputOneHex, dl is max allowed hex value
   mov ch,cl         ;to know if at beginning of input
   
inputNextCharacter:
   mov dh,0a0h       ;normal function code if not at end or beginning of input
   cmp cl,ch
   jne notAtBeginningOfInput
   and dh,0dfh       ;disable backspace
notAtBeginningOfInput:
   cmp cl,0
   jne notAtEndOfInput
   and dh,7fh        ;disable echo
   or dh,50h         ;allow for enter, disable normal characters
notAtEndOfInput:
   call pInputOneHex ;get next character
   shl ah,1          ;see if user hit space
   jc doneInputManyHex;return with carry flag set
   shl ah,1          ;see if user hit enter
   jc doneInputManyHexClearCarry
   shl ah,1          ;see if user hit backspace
   jnc backspaceNotPressed
   inc cl
   shr bx,1          ;clear out deleted character
   shr bx,1
   shr bx,1
   shr bx,1
   jmp inputNextCharacter
   
backspaceNotPressed:
   shl bx,1          ;make room for new character
   shl bx,1
   shl bx,1
   shl bx,1
   or bl,al
   dec cl
   jmp inputNextCharacter

doneInputManyHexClearCarry:
   clc
doneInputManyHex:
   pop dx,cx,ax
   ret
pInputManyHex endp
