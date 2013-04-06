;Operating system interrupt requests

;inputs:    ah - function code
;outputs:   dependent on function code
int21h proc far
checkBackToMainMenu:
   cmp ah,00h
   jne checkInputWithEcho
   ;TODO: write procedure to pop stack back to main program. Be careful!
   jmp osInterruptComplete
   
checkInputWithEcho:
   cmp ah,01h
   jne checkInputWithoutEcho
   call pInputWithEcho
   mov ah,01h        ;restore value of ah
   jmp osInterruptComplete

checkInputWithoutEcho:
   cmp ah,07h
   jne checkStringOutput
   call pInputWithoutEcho
   mov ah,07h        ;restore value of ah
   jmp osInterruptComplete

checkStringOutput:
   cmp ah,09h
   jne osInterruptComplete
   call pStringOutput
   jmp osInterruptComplete

osInterruptComplete:
   iret
int21h endp

;inputs:    none
;outputs:   al - input character
pInputWithEcho proc near
   push dx

   call pMakeCursorVisible
   mov dl,0fh        ;display on, blinking cursor
   call pOutputScreenCommand

   call pInputWithoutEcho

   mov dl,0ch        ;display on, no cursor
   call pOutputScreenCommand

   mov dl,al
   mov ah,09h        ;print character
   int 10h
   
   pop dx
   ret
pInputWithEcho endp

;inputs:    none
;outputs:   al - input character
pInputWithoutEcho proc near
   push dx
   
inputCharacterAgain:
   xor ah,ah
   int 16h
   call pCheckSpecialCharacters
   jc inputCharacterAgain

   pop dx
   ret
pInputWithoutEcho endp

;inputs:    ds:dx - string address
;outputs:   none - prints until a null byte is encountered
pStringOutput proc near
   push ax,si,dx
   
   mov si,dx
   mov ah,09h        ;function code to print character

printCharacter:
   mov dl,[si]
   cmp dl,00h
   je outputStringComplete
   int 10h
   inc si
   jmp printCharacter

outputStringComplete:
   mov ah,0ah        ;refresh the screen
   int 10h  

   pop dx,si,ax
   ret
pStringOutput endp

;inputs:    al - inputted character
;outputs:   carry flag set if it was a special keystroke
pCheckSpecialCharacters proc near
   push ax,bx
   
   mov bl,al
   
   mov ax,0601h      ;set up for scrolling up once
   cmp bl,'['
   je scrollOnce
   cmp bl,'{'
   je scrollFourTimes
   mov ah,07h        ;set up for scrolling down
   cmp bl,']'
   je scrollOnce
   cmp bl,'}'
   je scrollFourTimes
   clc
   jne doneCheckingSpecial
   
scrollFourTimes:
   mov al,04h
scrollOnce:
   int 10h           ;scroll screen
   mov ah,0ah
   int 10h           ;refresh screen
   stc
   
doneCheckingSpecial:
   pop bx,ax
   ret
pCheckSpecialCharacters endp

;inputs:    none
;outputs:   none, RAM pointers updated as appropriate
pMakeCursorVisible proc near
   push ax,dx,ds
   
   mov ds,ramSegment
   
   call pGetCursorPosition
   add dh,1dh        ;fast way to go back 3 rows
   call pValidateRowAndColumn
   mov dl,[currentPrintRow]
   
   cmp dl,dh         ;only refresh screen if necessary
   je cursorIsVisible
   mov [currentPrintRow],dh
   mov ah,0ah
   int 10h

cursorIsVisible:
   pop ds,dx,ax
   ret
pMakeCursorVisible endp
