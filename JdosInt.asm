;Operating system interrupt requests

;inputs:    none
;outputs:   al - input character
mInputWithEcho macro
   
endm

;inputs:    dl - character to output
;outputs:   none
pOutputCharacter proc near
   
pOutputCharacter endp

;inputs:    none
;outputs:   al - input character
mInputWithoutEcho macro
   
endm

;inputs:    ds:dx - string address
;outputs:   none - prints until a $ is encountered
mStringOutput macro
   push ax
   push si

   cld         ;increment SI on lodsb
   
printCharacter:
   lodsb
   cmp al,'$'
   je done
   mov dl,al
   call pOutputCharacter
   jmp printCharacter

done:
   pop si
   pop ax
endm

;inputs:    ah - function code
;outputs:   dependent on function code
int21h proc far
checkInputWithEcho:
   cmp ah,01h
   jne checkOutputCharacter
   mInputWithEcho

checkOutputCharacter:
   cmp ah,02h
   jne checkInputWithoutEcho
   call pOutputCharacter

checkInputWithoutEcho:
   cmp ah,07h
   jne checkStringOutput
   mInputWithoutEcho

checkStringOutput:
   cmp ah,09h
   jne done
   mStringOutput

done:
   iret
int21h endp
