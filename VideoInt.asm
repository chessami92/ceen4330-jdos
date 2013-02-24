;Video service requets. 

;inputs:    command code to send
;outputs:   sends command with 40us of delay
mOutputScreenData macro
   mov ah,lcdDataBits
   mov al,#1
   call pOutputToScreen
   mDelay40us
#em

;inputs:    command code to send
;outputs:   sends command with 40us of delay
mOutputScreenCommand macro
   mov ah,lcdCommandBits
   mov al,#1
   call pOutputToScreen
   mDelay40us
#em

;inputs:    none
;outputs:   none, display initialized and ready to use
pInitializeDisplay proc near
   push ax,ds

   mov ax,lcdSegment
   mov ds,ax

   mDelayMs 15          ;must to wait 15ms before setup is allowed
   
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

   push cx,di,es

   xor ax,ax
   mov es,ax
   mov di,cursorColumn

   stosw             ;clear cursor position for video display
   mov ax,0300h      ;last row printed is 3rd row, current row is 0th row
   stosw

   mov ax,2020h      ;set all display bytes to space
   mov cx,140h
   rep stosw

   pop es,di,cx,ax
   ret
pInitializeDisplay endp

;inputs:    dh - row (00h is top)
;           dl - column (0-19)
;outputs:   cursor changed to position dh:dl
;           screen updated if cursor not present on current rows
pSetCursorPosition proc near
   ret
pSetCursorPosition endp

;inputs:    none
;outputs:   dh - row (00h is top, 1fh is bottom)
;           dl - column (0-19)
pGetCursorPosition proc near
   push ax,ds
   xor ax,ax         ;change to RAM segment
   mov ds,ax

   mov dx,[cursorColumn]

   pop ds,ax
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
   ret
pScrollWindowDown endp

;inputs:    al - the character to print
;outputs:   character put on display
;           if cursor is not currently visible, screen scrolled to cursor first
pOutputCharacter proc near 
   ;TODO: make sure cursor is visible on screen
   push ax,dx

   call pGetCursorPosition
   mOutputScreenData al

   pop dx,ax
   ret
pOutputCharacter endp

;inputs:    ah - function code
;outputs:   dependent on function code
int10h proc far
   push ds

   mov ds,lcdSegment

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
   jne checkOutputCharacter
   call pScrollWindowDown
   jmp videoInterruptComplete

checkOutputCharacter:
   cmp ah,09h
   jne videoInterruptComplete
   call pOutputCharacter

videoInterruptComplete:
   pop ds
   iret
int10h endp

;Screen hardware: X, E, RS, R/W~, D7-D4
lcdCommandBits EQU 00000000xb
lcdDataBits EQU 00100000xb

;inputs:    al - the decoded byte to send to the screen
;           ds - the LCD segment
;outputs:   none, al sent to screen with enable
mOutputDecodedByte macro
   or al,01000000xb  ;send data with enable
   mov [lcdOffset],al

   nop               ;make sure data is latched
   nop
   and al,10111111xb ;send data without enable 
   mov [lcdOffset],al
#em

;inputs:    al - the command to be sent to the screen
;           ah - upper 4 bits are to distinguish between data and command
;           ds - the LCD segment
;outputs    none, al sent to the screen
pOutputToScreen proc near
   push ax

   shr al,1
   shr al,1
   shr al,1
   shr al,1
   or al,ah
   mOutputDecodedByte;output first nibble

   nop               ;wait before sending next data
   nop
   nop

   pop ax            ;refresh ax
   push ax
   and al,0fh        ;clear upper nibble 
   or al,ah
   mOutputDecodedByte;output second nibble

   pop ax
   ret
pOutputToScreen endp
