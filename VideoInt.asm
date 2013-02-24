;Video service requets. 
;Screen hardware: X, E, RS, R/W~, D7-D4

;inputs:    al=00
;outputs:   none, screen is cleared
pScrollWindowUp proc near
   ret
pScrollWindowUp endp

;inputs:    command code to send
;outputs:   sends command with 40us of delay
mOutputCommand macro
   mov al,#1
   call pOutputCommand
   mDelay40us
#em

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
;outputs    none, al sent to the screen
pOutputCommand proc near
   push ax

   shr al,1
   shr al,1
   shr al,1
   shr al,1
   mOutputDecodedByte

   nop               ;wait before sending next data
   nop
   nop

   pop ax            ;refresh ax
   push ax
   and al,0fh        ;clear upper nibble 
   mOutputDecodedByte

   pop ax
   ret
pOutputCommand endp

;inputs:    none
;outputs:   none, display initialized and ready to use
pInitializeDisplay proc near
   push ax,ds

   mov ax,lcdSegment
   mov ds,ax

   mDelayMs 15          ;must to wait 15ms before setup is allowed
   
   mOutputCommand 30h   ;base initialization
   mDelayMs 5
   mOutputCommand 30h
   mDelay40us
   mDelay40us
   mOutputCommand 30h

   mOutputCommand 28h   ;function set to 4-bit interface, 5x8 dot font
   mOutputCommand 08h   ;display off
   mOutputCommand 01h   ;clear display
   mDelayMs 2
   mOutputCommand 0fh   ;display on, blinking cursor
   mOutputCommand 06h   ;entry mode, auto-increment
   
   pop ax,ds
   ret
pInitializeDisplay endp

;inputs:    ah - function code
;outputs:   dependent on function code
int10h proc far
   push ds

   mov ds,lcdSegment

checkInitializeDisplay:
   cmp ah,00h
   jne checkScrollWindowUp
   call pInitializeDisplay
   jmp videoInterruptComplete

checkScrollWindowUp:
   cmp ah,06h
   jne videoInterruptComplete
   call pScrollWindowUp

videoInterruptComplete:
   pop ds
   iret
int10h endp
