;Video service requets. 

;Screen hardware: X, E, RS, R/W~, D7-D4
lcdCommandBits EQU 10000000xb
lcdDataBits    EQU 10100000xb

;inputs:    command code to send
;outputs:   sends command with 40us of delay
mOutputScreenCommand macro
   push dx
   
   mov dh,lcdCommandBits
   mov dl,#1
   call pOutputToScreen
   mDelay40us
   
   pop dx
#em

;inputs:    dl - ascii character to send
;outputs:   sends command with 40us of delay
;           corrects lcd address for proper line wrapping
pOutputScreenData proc near
   push dx,ds
   mov dh,lcdDataBits
   call pOutputToScreen
   mDelay40us
   
   mov ds,ramSegment
   
   mov dl,[currentLcdCursor]
   inc dl
checkFirstLcdRow:
   cmp dl,20
   jne checkSecondLcdRow
   mOutputScreenCommand 0c0h
   jmp correctLcdCursor
checkSecondLcdRow:
   cmp dl,40
   jne checkThirdLcdRow
   mOutputScreenCommand 094h
   jmp correctLcdCursor
checkThirdLcdRow:
   cmp dl,60
   jne checkZerothLcdRow
   mOutputScreenCommand 0d4h
   jmp correctLcdCursor
checkZerothLcdRow:
   cmp dl,80
   jne correctLcdCursor
   mOutputScreenCommand 080h
   xor dl,dl
   jmp correctLcdCursor

correctLcdCursor:
   mov [currentLcdCursor],dl
   
   pop ds,dx
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
   jne checkPrintCharacterToRam
   call pScrollWindowDown
   jmp videoInterruptComplete

checkPrintCharacterToRam:
   cmp ah,09h
   jne checkPrintCurrentScreen
   call pPrintCharacterToRam
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
   push ds

   mov ds,lcdSegment

   mDelayMs 15       ;must to wait 15ms before setup is allowed
   
   mOutputScreenCommand 30h   ;base initialization
   mDelayMs 5
   mOutputScreenCommand 30h
   mDelay40us
   mDelay40us
   mOutputScreenCommand 30h

   mOutputScreenCommand 28h   ;function set to 4-bit interface, 5x8 dot font
   mOutputScreenCommand 08h   ;display off
   mOutputScreenCommand 01h   ;clear display
   mDelayMs 2
   mOutputScreenCommand 0fh   ;display on, blinking cursor
   mOutputScreenCommand 06h   ;entry mode, auto-increment
   pop ds

   push ax,cx,di,es

   mov es,0000h
   mov di,currentLcdCursor

   stosb             ;current lcd location is 0
   stosw             ;cursor is at row 0, column 0
   stosb             ;current row is 0
   mov al,03h        ;last row printed is 3
   stosb

   mov ax,2020h      ;set all display bytes to space
   mov cx,140h
   rep stosw

   pop es,di,cx,ax
   ret
pInitializeDisplay endp

;inputs:    ds - RAM segment
;           dh - row (00h is top, 1fh is bottom)
;           dl - column (0-19)
;outputs:   cursor changed to position dh:dl
;           screen updated if cursor not present on current rows
pSetCursorPosition proc near
   ;TODO: show or hide cursor as necessary
   call pValidateRowAndColumn

   mov [cursorColumn],dx
   ret
pSetCursorPosition endp

;inputs:    ds - RAM segment
;outputs:   dh - row (00h is top, 1fh is bottom)
;           dl - column (0-19)
pGetCursorPosition proc near
   mov dx,[cursorColumn]
   ret
pGetCursorPosition endp

;inputs:    al - number of lines to scroll up,
;              al=00h means to clear display
;outputs:   none - does not update cursor
pScrollWindowUp proc near
   ret
pScrollWindowUp endp

;inputs:    al - number of lines to scroll down
;outputs:   none - does not update cursor
pScrollWindowDown proc near
   ;TODO: show or hide cursor as necessary
   ret
pScrollWindowDown endp

;inputs:    ds - RAM segment
;           al - the character to print
;              if al = 0ah, then spaces are put in RAM til EOL
;outputs:   character put in display RAM
;           if cursor is not currently visible, screen scrolled to cursor first
pPrintCharacterToRam proc near 
   push bx,dx
   
   mov ds,0000h      ;change to RAM segment

   call pGetCursorPosition    ;dh = row, dl = column
   call pConvertToRamOffset   ;bx = RAM offset given dx
   cmp al,0ah
   jne nonNewLine    ;else there is new line, print spaces til EOL
   
putSpacesInRam:
   mov B[bx],20h     ;put space in RAM
   inc bx            ;increment RAM pointer and column counter
   inc dl
   cmp dl,20         ;see if at last column
   je characterInRam
   jne putSpacesInRam

nonNewLine:
   mov [bx],al       ;store character in RAM
   inc dl            ;increment column

characterInRam:
   call pSetCursorPosition ;update cursor position

   mov bh,[lastScreenUsed] ;validate what screen is currently being used.
   sub dh,bh
   jns doNotAdd20h
   add dh,20h
doNotAdd20h:
   cmp dh,4
   jb lastScreenUsedValid
   call pGetCursorPosition ;last screen is not valid, put screen so cursor is at bottom
   add dh,1ch        ;fast way to subtract 4 with the validate procedure
   call pValidateRowAndColumn
   mov [lastScreenUsed],dh

lastScreenUsedValid:
   call pMakeCursorVisible ;ensure cursor is visible
   
   pop dx,bx
   ret
pPrintCharacterToRam endp

;inputs:    none
;outputs:   none, prints 4, 20 character rows starting at the currentPrintRow in RAM
pPrintCurrentScreen proc near
   ;TODO: show or hide cursor as necessary
   push cx,dx,ds,si
   
   mov ds,ramSegment

   xor si,si
   mov si,[currentPrintRow]
   add si,screenData ;shift by starting offset
   
   push ax
   mov ax,si
   call pOutputToLeds
   mDelayMs 5000
   pop ax

   mov cx,80         ;characters to print
   
printCharactersToLcd:
   mov dl,[si]
   call pOutputScreenData
   inc si
   loop printCharactersToLcd
   
   pop si,ds,dx,cx
pPrintCurrentScreen endp

;inputs:    none
;outputs:   none, RAM pointers updated as appropriate
pMakeCursorVisible proc near
   push ax,ds
   
   mov ds,0000h
   
   mov al,[lastScreenUsed]
   mov [currentPrintRow],al

   pop ds,ax
pMakeCursorVisible endp

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

;input:     dx - row and column
;output:    bx - 20*dh+dl
pConvertToRamOffset proc near
   push ax,dx

   xor bx,bx         ;clear bx
   mov bl,dh         ;put row in bx
   
   shl bx,1          ;multiply by 4
   shl bx,1
   mov ax,bx
   shl bx,1          ;multiply by 4 again
   shl bx,1
   add bx,ax         ;16*dh+4*dh

   xor dh,dh         ;clear row to only have column
   add bx,dx         ;add in column

   add bx,screenData ;shift by starting offset

   pop dx,ax
pConvertToRamOffset endp

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
