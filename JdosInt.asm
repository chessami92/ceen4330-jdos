;Operating system interrupt requests

;inputs:    ah - function code
;outputs:   dependent on function code
int21h proc far
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

   call pInputWithoutEcho

   mov dl,al
   mov ah,09h
   int 10h
   
   pop dx
   ret
pInputWithEcho endp

;inputs:    none
;outputs:   al - input character
pInputWithoutEcho proc near
   push dx

   mov dl,0fh        ;display on, blinking cursor
   call pOutputScreenCommand

   xor ah,ah
   int 16h

   mov dl,0ch        ;display on, no cursor
   call pOutputScreenCommand

   pop dx
   ret
pInputWithoutEcho endp

;inputs:    ds:dx - string address
;outputs:   none - prints until a null byte is encountered
pStringOutput proc near
   push ax,dx,si,es,di
   
   mov si,dx
   mov ah,03h        ;get cursor position code for int 10h
   mov es,ramSegment
   int 10h           ;dh = row, dl = column
   call pConvertToRamOffset ;di = correct destination
   cld               ;increment SI on lodsb

printCharacter:
   lodsb
   cmp al,00h
   je outputStringComplete
   stosb
   jmp printCharacter

outputStringComplete:
   mov ah,0ah        ;refresh the screen
   int 10h  

   pop di,es,si,dx,ax
   ret
pStringOutput endp
