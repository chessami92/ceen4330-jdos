;Video service requets. 

;Screen hardware: speaker, E, RS, R/W~, D7-D4
lcdCommandBits EQU 10000000xb
lcdDataBits    EQU 10100000xb

;inputs:    dl - command code to send
;outputs:   sends command with 40us of delay
pOutputScreenCommand proc near
   push dx
   
   mov dh,lcdCommandBits
   call pOutputToScreen
   mDelay40us
   
   pop dx
   ret
pOutputScreenCommand endp

;command to send to change to row 1, 2, 3, and 0 respectively
screenLines db 0c0h, 094h, 0d4h, 080h
;inputs:    dl - ascii character to send
;outputs:   sends command with 40us of delay
;           corrects lcd address for proper line wrapping
pOutputScreenData proc near
   push ax,bx,dx,ds
   mov dh,lcdDataBits
   call pOutputToScreen
   mDelay40us
   
   mov ds,ramSegment
   
   mov dl,[currentLcdCursor]
   inc dl

   xor ax,ax         ;see if dl is now a multiple of 20
   mov al,dl
   mov bl,20
   div bl
   cmp ah,00h
   jne correctLcdCursor
   
   ;need to move the cursor on the screen
   dec ax            ;shift to 0-based counting
   add ax,offset screenLines
   mov bx,ax
   push dx
   mov dl,cs:[bx]
   call pOutputScreenCommand
   pop dx

   cmp dl,80
   jne correctLcdCursor
   xor dl,dl         ;restart at beginning

correctLcdCursor:
   mov [currentLcdCursor],dl
   
   pop ds,dx,bx,ax
   ret
pOutputScreenData endp

;inputs:    dl - the decoded byte to send to the screen
;           ds - the LCD segment
;outputs:   none, al sent to screen with enable
mOutputDecodedByte macro
   or dl,01000000xb  ;send data with enable
   mov [lcdOffset],dl

   nop               ;make sure data is latched
   nop
   and dl,10111111xb ;send data without enable 
   mov [lcdOffset],dl
#em

;inputs:    dl - the command to be sent to the screen
;           dh - upper 4 bits are to distinguish between data and command
;outputs    none, al sent to the screen
pOutputToScreen proc near
   push ds,dx
   
   mov ds,lcdSegment
   
   shr dl,1
   shr dl,1
   shr dl,1
   shr dl,1
   or dl,dh
   mOutputDecodedByte;output first nibble

   nop               ;wait before sending next data
   nop
   nop

   pop dx            ;refresh dx
   push dx
   and dl,0fh        ;clear upper nibble 
   or dl,dh
   mOutputDecodedByte;output second nibble

   pop dx,ds
   ret
pOutputToScreen endp

;inputs:    ah - function code
;outputs:   dependent on function code
int10h proc far
checkInitializeDisplay:
   cmp ah,00h
   jne checkSetCursorPosition
   call pInitializeDisplay
   jmp videoInterruptComplete

checkSetCursorPosition:
   cmp ah,02h
   jne checkGetCursorPosition
   call pSetCursorPosition
   jmp videoInterruptComplete

checkGetCursorPosition:
   cmp ah,03h
   jne checkScrollWindowUp
   call pGetCursorPosition
   jmp videoInterruptComplete

checkScrollWindowUp:
   cmp ah,06h
   jne checkScrollWindowDown
   call pScrollWindowUp
   jmp videoInterruptComplete

checkScrollWindowDown:
   cmp ah,07h
   jne checkPrintCharacter
   call pScrollWindowDown
   jmp videoInterruptComplete

checkPrintCharacter:
   cmp ah,09h
   jne checkPrintCurrentScreen
   call pPrintCharacter
   jmp videoInterruptComplete

checkPrintCurrentScreen:
   cmp ah,0ah
   jne videoInterruptComplete
   call pPrintCurrentScreen

videoInterruptComplete:
   iret
int10h endp

;inputs:    none
;outputs:   none, display initialized and ready to use
pInitializeDisplay proc near
   push dx,ds

   mov ds,lcdSegment

   mDelayMs 15       ;must to wait 15ms before setup is allowed
   
   mov dl,30h
   call pOutputScreenCommand
   mDelayMs 5
   call pOutputScreenCommand
   mDelay40us
   mDelay40us
   call pOutputScreenCommand

   mov dl,28h
   call pOutputScreenCommand  ;function set to 4-bit interface, 5x8 dot font
   mov dl,08h
   call pOutputScreenCommand  ;display off
   mov dl,01h
   call pOutputScreenCommand  ;clear display
   mDelayMs 2
   mov dl,0ch
   call pOutputScreenCommand  ;display on, no cursor
   mov dl,06h
   call pOutputScreenCommand  ;entry mode, auto-increment
   pop dx,ds

   push ax,cx,di,es

   mov es,0000h
   mov di,currentLcdCursor

   stosb             ;current lcd location is 0
   stosw             ;cursor is at row 0, column 0
   stosb             ;current row is 0

   mov ax,2020h      ;set all display bytes to space
   mov cx,140h
   rep stosw

   pop es,di,cx,ax
   ret
pInitializeDisplay endp

;inputs:    dh - row (00h is top, 1fh is bottom)
;           dl - column (0-19)
;outputs:   cursor changed to position dh:dl
;           screen updated if cursor not present on current rows
pSetCursorPosition proc near
   push ds
   
   call pValidateRowAndColumn
   mov ds,ramSegment
   mov [cursorColumn],dx
   
   pop ds
   ret
pSetCursorPosition endp

;inputs:    none
;outputs:   dh - row (00h is top, 1fh is bottom)
;           dl - column (0-19)
pGetCursorPosition proc near
   push ds
   
   mov ds,ramSegment
   mov dx,[cursorColumn]
   
   pop ds
   ret
pGetCursorPosition endp

;inputs:    al - number of lines to scroll
;outputs:   none - decrements the current print row
pScrollWindowUp proc near
   push ax,bx,dx,ds

   mov ds,ramSegment
   xor dx,dx

scrollWindowUp:
   mov dh,[currentPrintRow]
   add dh,numScreenLines - 1
   call pValidateRowAndColumn

   mov bx,dx         ;see if trying to look past end of buffer
   call pGetCursorPosition
   cmp dh,bh
   je cannotScrollBack
   mov [currentPrintRow],bh
   dec al
   jnz scrollWindowUp
   
cannotScrollBack:
   pop ds,dx,bx,ax
   ret
pScrollWindowUp endp

;inputs:    al - number of lines to scroll
;outputs:   none - increments the current print row
pScrollWindowDown proc near
   push ax,bx,dx,ds

   mov ds,ramSegment
   xor dx,dx

scrollWindowDown:
   mov dh,[currentPrintRow]
   inc dh
   call pValidateRowAndColumn

   mov bx,dx         ;see if already at newest part of buffer
   call pGetCursorPosition
   add dh,numScreenLines - 2
   call pValidateRowAndColumn
   cmp dh,bh
   je cannotScrollForward
   mov [currentPrintRow],bh
   dec al
   jnz scrollWindowDown

cannotScrollForward:
   pop ds,dx,bx,ax
   ret
pScrollWindowDown endp

;inputs:    dl - the character to print
;              if dl = 0ah, then spaces are put in RAM til EOL
;outputs:   character put in display RAM
;           if cursor is not currently visible, screen scrolled to cursor first
pPrintCharacter proc near 
   push ax,bx,dx,ds
   
   mov al,dl         ;put new character in al
   mov ds,ramSegment ;change to RAM segment

   call pGetCursorPosition    ;dh = row, dl = column
   call pConvertToRamOffset   ;bx = RAM offset given dx

   cmp al,0ah
   jne nonNewLine    ;else there is new line, print spaces til EOL
   
putSpacesInRam:
   mov B[bx],20h     ;put space in RAM
   inc dl            ;increment column counter
   call pConvertToRamOffset
   cmp dl,20         ;see if at last column
   je characterInRam
   jne putSpacesInRam

nonNewLine:
   cmp al,08h
   jne nonBackspace
   sub dl,1          ;make last character a space
   jns noAdjustingRowColumn
   mov dl,19         ;make end of row of last row
   add dh,numScreenLines - 1

noAdjustingRowColumn:
   call pConvertToRamOffset
   mov B[bx],20h
   push dx
   mov dl,10h
   call pOutputScreenCommand
   sub B[currentLcdCursor],2
   mov dl,20h
   call pOutputScreenData
   mov dl,10h
   call pOutputScreenCommand
   pop dx
   jmp characterInRam

nonBackspace:
   push dx
   mov dl,al
   call pOutputScreenData
   pop dx
   mov [bx],al       ;store character in RAM
   inc dl            ;increment column

characterInRam:
   call pSetCursorPosition ;update cursor position
   
   pop ds,dx,bx,ax
   ret
pPrintCharacter endp

;inputs:    none
;outputs:   none, prints 4, 20 character rows starting at the currentPrintRow in RAM
pPrintCurrentScreen proc near
   push bx,cx,dx,ds
   
   mov dl,01h        ;clear screen
   call pOutputScreenCommand
   mDelayMs 2
   mov dl,080h       ;move to position 0 of screen
   call pOutputScreenCommand
   
   mov ds,ramSegment
   
   xor dx,dx         ;starting at the beginning of the screen
   mov [currentLcdCursor],dl
   
   mov dh,[currentPrintRow]
   mov cx,80         ;number of characters to print
   
printCharactersToLcd:
   call pConvertToRamOffset
   push dx           ;save current row and column
   mov dl,[bx]
   call pOutputScreenData
   pop dx
   
   inc dl
   call pValidateRowAndColumn
   
   mov bx,dx         ;check if we have reached cursor position
   call pGetCursorPosition
   cmp bx,dx
   je printedToCursorLocation
   
   mov dx,bx         ;restore the value of dx if not
   loop printCharactersToLcd

printedToCursorLocation:
   pop ds,dx,cx,bx
   ret
pPrintCurrentScreen endp

;inputs:    dh - row
;           dl - column
;outputs:   dx - valid row and valid column
pValidateRowAndColumn proc near
   cmp dl,20
   jb validCursorColumn

adjustCursorColumn:
   sub dl,20         ;take off 20 and add one to row
   inc dh            ;add one to row
   cmp dl,20
   jae adjustCursorColumn

validCursorColumn:
   cmp dh,20h
   jb validCursorRow
   
adjustCursorRow:
   sub dh,20h
   cmp dh,20h
   jae adjustCursorRow

validCursorRow:
   ret
pValidateRowAndColumn endp

;input:     dh - row
;           dl - column
;output:    bx - 20*dh+dl+screenData offset in RAM
pConvertToRamOffset proc near
   push ax,dx

   xor ax,ax
   mov al,dh
   mov dh,20
   mul dh            ;multiply row by 20

   xor dh,dh         ;clear row to only have column
   add ax,dx         ;add in column
   add ax,screenData ;shift by starting offset

   mov bx,ax

   pop dx,ax
   ret
pConvertToRamOffset endp
