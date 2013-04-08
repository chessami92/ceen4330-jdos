;inputs:    none
;outputs:   ss - set to a valid point in ram
;           sp - points
mInitializeStackPointer macro
   xor ax,ax         ;stack segment in RAM
   mov ss,ax
   mov sp,stackBegin ;point to top of stack
#em

;inputs:    none
;outputs:   none
mLoadInterruptVectorTable macro
   push es,ds,di,si,ax,bx,cx

   mov es,0000h
   xor di,di
   mov ds,0f000h
   mov si,offset interruptTable

   cld               ;increment on string instructions

   mov cx,256        ;how many entries in the IVT

   mov ax,offset defaultInterrupt
   mov bx,romSegment

storeDefaultInformation:
   stosw             ;store IP
   xchg ax,bx
   stosw             ;store CS
   xchg ax,bx
   loop storeDefaultInformation

storeDefinedInterrupts:
   xor ah,ah         ;make sure ah is cleared, otherwise address wil be wrong
   lodsb             ;get which interrupt is to be stored
   mov di,ax
   shl di,1          ;multiply by 4 to get address
   shl di,1
   movsw             ;copy IVT entry
   movsw
   cmp si,endInterruptTable ;see if we have reached end of IVT entries
   jne storeDefinedInterrupts

   pop cx,bx,ax,si,di,ds,es
#em

mInitializeInterruptController macro
   push ds

   mov ds,intControllerSegment

   mov B[intCommand1],00011011xb ;level triggered, single, ICW4 needed 
   mov B[intCommand2],00001000xb ;start address of 08h
   mov B[intCommand2],00000011xb ;auto EOI, 8086 uP

   mov B[intCommand2],11111100xb ;ignore interrupts 2-7 as they are not connected

   pop ds
#em

mInitializeKeyboard macro
   mov ah,04h
   int 16h
#em

mInitializeDisplay macro
   xor ah,ah
   int 10h
#em

memoryGood db 0ah, ' Memory test passed', 0
memoryBad db  0ah, ' Memory test failed', 0
;inputs:    none
;outputs:   none - memory checked by storing words on both even and odd addresses.
;              If bad, it is printed on the LCD, likewise for good
pTestMemory proc near
   push ax,bx,cx,dx,ds,si
   
   mov ds,ramSegment ;begin at top of RAM, work way down
   xor ax,ax
   mov bx,0fffeh

   mov cx,0aaaah
   mov dx,05555h

checkRam:   
   mov si,[bx]       ;save memory data
   mov [bx],cx       ;test with aaaah
   cmp cx,[bx]
   jne memoryTestFailed
   mov [bx],dx       ;test with 5555h
   cmp dx,[bx]
   jne memoryTestFailed
   mov [bx],si       ;restore memory data
   dec bx
   jnz checkRam

   mov dx,offset memoryGood
   jmp displayTestResult

memoryTestFailed:
   call pOutputToLeds
   mov dx,offset memoryBad

displayTestResult:
   mov ah,09h
   mov ds,romSegment
   int 21h
   mDelayMs 500

   pop si,ds,dx,cx,bx,ax
   ret
pTestMemory endp

splashScreen db ' ', 18 DUP '*', ' *  CEEN 4330 2013  *','*  by Josh DeWitt  *', ' ******************', 0
mOutputSplashScreen macro
   push ax,dx,ds
   
   mov ah,09h
   mov ds,romSegment
   mov dx,offset splashScreen
   int 21h
   
   pop ds,dx,ax
#em

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   mInitializeStackPointer
   mLoadInterruptVectorTable
   mInitializeInterruptController
   mInitializeKeyboard
   mInitializeDisplay
   sti               ;allow interrupts now that IVT is initialized
   mOutputSplashScreen
   call pTestMemory
   
callMainMenu:
   call pMainMenu
   jmp callMainMenu
   
   ;no return because this procedure was jumped to, not called
pJdosInit endp

mainMenuPrompt db '*****Main Menu******', '0 - New user guide', 0ah, '1 - Light show'
               db 0ah, '2 - Free typing', 0ah, '3 - Memory debug', 0ah, '4 - Set system clock', 0
;inputs:    none
;outputs:   none
pMainMenu proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset mainMenuPrompt
   mov ah,09h
   int 21h
   mov dx,0004h
   call pInputOneHex

checkNewUserGuide:
   cmp al,0
   jne checkLightShow
   call pNewUserGuide
   jmp mainMenuComplete
checkLightShow:
   cmp al,1
   jne checkFreeTyping
   call pLedPatternMenu
   jmp mainMenuComplete
checkFreeTyping:
   cmp al,2
   jne checkMemoryDebug
   mOutputCharacter 0ah
   mov ah,01
continueTyping:
   int 21h
   jmp continueTyping
checkMemoryDebug:
   cmp al,3
   jne checkSetClock
   call pDebugMenu
   jmp mainMenuComplete
checkSetClock:
   cmp al,4
   jne checkPlaySong
   call pSetClock
   jmp mainMenuComplete
checkPlaySong:
   cmp al,5
   jne mainMenuComplete

mainMenuComplete:
   pop ds,dx,ax
   ret
pMainMenu endp

userGuide db '***New User Guide***', 'Press ', 1, ' or ', 2, ' to', 0ah, 'scroll.', 0ah
          db 'The black button', 0ah, 'above is shift.', 0ah, 'Press shift + ', 1, ' or ', 2, 'to scroll a page.', 0ah
          db 7fh, ' is backspace.', 0ah, 7eh, ' is space.', 0ah, 'The red button above', 'is ctrl.', 0ah
          db 'Press ctrl + a for', 0ah, 'enter or to confirm.', 'Press ctrl + c to', 0ah, 'return to the main', 0ah, 'menu at any time.', 0
;inputs:    none
;outputs:   none, user give a briefing on how to use the system
pNewUserGuide proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset userGuide
   mov ah,09h
   int 21h
waitToReturnToMenu:
   mov ah,07h        ;user should press control + c to get back to main menu
   int 21h
   jmp waitToReturnToMenu
   
   pop ds,dx,ax
   ret
pNewUserGuide endp

ledMenuPrompt db '******LED Menu******', 'Press 0 or 1 to', 0ah, 'select a pattern.', 0
;inputs:    none
;outputs:   none, user shown different patterns on the LEDs
pLedPatternMenu proc near
   push ax,bx,cx,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset ledMenuPrompt
   mov ah,09h
   int 21h

   mov dx,0001h
   call pInputOneHex

checkPatternZero:
   cmp al,0
   jne checkPatternOne
   xor ax,ax
   xor bx,bx
   inc bx
   mov cx,39
rotateLed:
   cmp al,08h
   clc
   jne normalLedRotate
   xor al,al
   stc
normalLedRotate:
   rcl bx,1
   rcl al,1
   call pOutputToLeds
   mDelayMs 100
   loop rotateLed
   mov al,0ffh
   mov bx,0ffffh
   mov cx,8
allLedFlash:
   call pOutputToLeds
   not al
   not bx
   mDelayMs 250
   loop allLedFlash
   jmp ledPatternComplete
   
checkPatternOne:
   cmp al,1
   jne ledPatternComplete
   xor al,al
   xor bx,bx
   mov cx,256
binaryLedCount:
   inc bl
   inc bh
   inc al
   call pOutputToLeds
   mDelayMs 50
   loop binaryLedCount
   mov al,0fah
   mov bx,0aaaah
   mov cx,9
halfLedFlash:
   call pOutputToLeds
   not al
   not bx
   mDelayMs 250
   loop halfLedFlash
   
ledPatternComplete:  
   shr al,1
   rcr bx,1
   call pOutputToLeds
   mDelayMs 100
   cmp bx,0
   jne ledPatternComplete
   
   pop ds,dx,cx,bx,ax
   ret
pLedPatternMenu endp

pSetClock proc near
   ret
pSetClock endp
