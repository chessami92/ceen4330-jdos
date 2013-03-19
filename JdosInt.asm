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
;outputs:   none - prints until a $ is encountered
mStringOutput macro
   ;TODO: make this a null byte instead of the $
   push ax
   push si

   cld         ;increment SI on lodsb
   
printCharacter:
   lodsb
   cmp al,'$'
   je outputStringComplete
   mov dl,al
   call pPrintCharacterToRam
   jmp printCharacter

outputStringComplete:
   pop si
   pop ax
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
