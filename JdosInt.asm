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
   mov ah,0ah
   int 10h
   mov dl,0fh        ;display on, blinking cursor
   call pOutputScreenCommand

   call pInputWithoutEcho

   mov dl,0ch        ;display on, no cursor
   call pOutputScreenCommand

   mov dl,al
   mov ah,09h        ;print character to memory
   int 10h
   mov ah,0ah        ;refresh screen
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
   push ax,dx,si
   
   mov si,dx
   mov ah,09h        ;function code to print character

printCharacter:
   mov dl,[si]
   cmp dl,00h
   je outputStringComplete
   int 10h
   jmp printCharacter

outputStringComplete:
   mov ah,0ah        ;refresh the screen
   int 10h  

   pop si,dx,ax
   ret
pStringOutput endp

;inputs:    al - inputted character
;outputs:   carry flag set if it was a special keystroke
pCheckSpecialCharacters proc near
   push ax

checkScrollUpLine:
   cmp al,'['
   jne checkScrollUpPage
   mov ah,03h
   int 10h
   stc
   jmp doneCheckingCharacter
checkScrollUpPage:
   cmp al,'{'
   jne checkScrollDownLine
   mov ah,03h
   int 10h
   int 10h
   int 10h
   int 10h
   stc
   jmp doneCheckingCharacter
checkScrollDownLine:
   cmp al,']'
   jne checkScrollDownPage
   mov ah,06h
   int 10h
   stc
   jmp doneCheckingCharacter
checkScrollDownPage:
   cmp al,'}'
   jne noSpecialCharacter
   mov ah,06h
   int 10h
   int 10h
   int 10h
   int 10h
   stc
   jmp doneCheckingCharacter

noSpecialCharacter:
   clc

doneCheckingCharacter:
   pop ax
   ret
pCheckSpecialCharacters endp

;inputs:    none
;outputs:   none, RAM pointers updated as appropriate
pMakeCursorVisible proc near
   push dx

   call pGetCursorPosition
   cmp dl,00h
   jne notBeginningOfLine
   dec dh            ;skip back 5 lines instead of just 4

notBeginningOfLine:
   add dh,1dh        ;fast way to go back 4 rows and still include cursor row
   call pValidateRowAndColumn
   mov [currentPrintRow],dh

   pop dx
pMakeCursorVisible endp
