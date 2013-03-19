;Operating system interrupt requests

;inputs:    none
;outputs:   al - input character
mInputWithEcho macro
   
#em

;inputs:    none
;outputs:   al - input character
mInputWithoutEcho macro
   
#em

;inputs:    ds:dx - string address
;outputs:   none - prints until a null byte is encountered
mStringOutput macro
   push ax,si

   cld               ;increment SI on lodsb
   mov ah,09h        ;print character code for int 10h

printCharacter:
   lodsb
   cmp al,00h
   je outputStringComplete
   int 10h
   jmp printCharacter

outputStringComplete:
   mov ah,0ah        ;refresh the screen
   int 10h  

   pop si,ax
#em

;inputs:    ah - function code
;outputs:   dependent on function code
int21h proc far
checkInputWithEcho:
   cmp ah,01h
   jne checkInputWithoutEcho
   mInputWithEcho

checkInputWithoutEcho:
   cmp ah,07h
   jne checkStringOutput
   mInputWithoutEcho

checkStringOutput:
   cmp ah,09h
   jne osInterruptComplete
   mStringOutput

osInterruptComplete:
   iret
int21h endp
