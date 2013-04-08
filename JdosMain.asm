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
   stosb             ;store IP
   xchg ax,bx
   stosb             ;store CS
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

memoryGood db ' Memory test passed ', 0
memoryBad db  ' Memory test failed ', 0
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

   pop si,ds,dx,cx,bx,ax
   ret
pTestMemory endp

splashScreen db ' ', 18 DUP '*', ' *  CEEN 4330 2013  *','*  by Josh DeWitt  *', ' **Press any key***', 0
mOutputSplashScreen macro
   push ax,dx,ds
   
   mov ah,09h
   mov ds,romSegment
   mov dx,offset splashScreen
   int 21h

   mov ah,07h        ;wait for a key press
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
   call pTestMemory
   mOutputSplashScreen
   
   ;int 02h TODO: dump memory to see what is the default interrupt - should be iret

   sti               ;allow interrupts now that IVT is initialized
   
callMainMenu:
   call pMainMenu
   jmp callMainMenu
   
   ;no return because this procedure was jumped to, not called
pJdosInit endp

mainMenuPrompt db '*****Main Menu******', '0 - New user guide', 0ah, '1 - Light show'
               db 0ah, '2 - Play a song', 0ah, '3 - Memory debug', 0
;inputs:    none
;outputs:   none
pMainMenu proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset mainMenuPrompt
   mov ah,09h
   int 21h
   mov dx,0003h
   call pInputOneHex
   
   cmp al,0
   jne checkLightShow
   call pNewUserGuide
   jmp mainMenuComplete
checkLightShow:
   cmp al,1
   jne checkPlaySong
   call pMenuLedPattern
   jmp mainMenuComplete
checkPlaySong:

mainMenuComplete:
   pop ds,dx,ax
   ret
pMainMenu endp

userGuide db '***New User Guide***', 'Press ', 1, ' or ', 2, ' to', 0ah, 'scroll.', 0ah
          db 'The black button', 0ah, 'above is shift.', 0ah, 'Press shift + ', 1, ' or ', 2, 'to scroll a page.', 0ah
          db 7fh, ' is backspace.', 0ah, 7eh, ' is space.', 0ah, 'The red button above', 'is ctrl.', 0ah
          db 'Press ctrl + a to', 0ah, 'finish an entry.', 0ah, 'Press ctrl + c to', 0ah, 'return to the main', 0ah, 'menu at any time.', 0
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
   mov ah,07h
   int 21h
   jmp waitToReturnToMenu
   
   pop ds,dx,ax
pNewUserGuide endp

;inputs:    none
;outputs:   none, user shown different patterns on the LEDs
pMenuLedPattern proc near
   push ax,bx
   xor al,al
   mov bx,0aaaah
   call pOutputToLeds
   pop bx,ax
   ret
pMenuLedPattern endp
