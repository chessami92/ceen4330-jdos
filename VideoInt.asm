;Video service requets. 

msDelay EQU 291
;inputs:    none
;outputs:   none, continues after 1ms
mDelayOneMs macro
   push cx

   even           ;force assembler to align on even space
   mov cx,msDelay
fiveCCDelay:
   ;delay = .2us * (17 * cx + 11 + 4 + 5 + 8)
   loop fiveCCDelay ;17/5

   pop cx
#em

;inputs:    cx - number of ms to wait
;outputs:   none, returns after cx ms
pDelayMs proc near
   push cx

delayCxMs:
   mDelayOneMs
   loop delayCxMs

   pop cx
   ret
delayMs endp

;inputs:    data to send and the delay in ms required
mOutputToScreenWithDelay macro
   mov al,#1
   call pOutputToScreen
   mov cx,#2
   call pDelayMs
#em

;inputs:    ah - function code
;outputs:   dependent on function code
int10h proc far
checkInitializeDisplay:
   push ds

   mov ds,lcdSegment

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

;inputs:    al=00
;outputs:   none, screen is cleared
pScrollWindowUp proc near
   ret
pScrollWindowUp endp

;inputs:    ah - the control signals, set bit 5 to 1 for data, 0 for command
;              all other bits are required to be 0
;           al - lower nibble sent to screen
;outputs:   none, lower nibble sent to screen
mOutputNibble macro
   or al,ah          
   mov [lcdOffset],al;send data without enable, RS = passed value
   or al,01000000xb  ;send data with enable
   mov [lcdOffset],al
   nop               ;make sure data is latched
   nop
   and al,10111111xb  
   mov [lcdOffset],al;send data without enable
#em

;inputs:    ah - the control signals, set bit 5 to 1 for data, 0 for command
;           al - the data to be sent to the screen
;outputs:   none, dl sent to screen, upper nibble then lower
pOutputToScreen proc near
   ;screen is set up: lower nibble is d7-d4, 
   ;upper nibble is don't care, then E, RS, R/W~
   push ax

   shr al,1          ;take upper nibble to bottom
   shr al,1
   shr al,1
   shr al,1
   mOutputNibble
   nop               ;wait before sending next data
   nop
   nop
   pop ax            ;refresh ax
   push ax
   and al,0fh        ;clear upper nibble, already sent it
   mOutputNibble

   pop ax
   ret
pOutputToScreen endp

;inputs:    none
;outputs:   none, display initialized and ready to use
pInitializeDisplay proc near
   push ax, cx

   mov cx,15         ;have to wait 15ms before setup is allowed
   call pDelayMs
   
   mov ah,00100000b  ;code to send data

   mOutputToScreenWithDelay 30h, 16
   mOutputToScreenWithDelay 30h, 4
   mOutputToScreenWithDelay 30h, 1
   mOutputToScreenWithDelay 38h, 1
   mOutputToScreenWithDelay 08h, 1 
   mOutputToScreenWithDelay 01h, 2
   mOutputToScreenWithDelay 0ch, 1
   mOutputToScreenWithDelay 06h, 1
   
   pop cx, ax
   ret
pInitializeDisplay endp
