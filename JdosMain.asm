;inputs:    none
;outputs:   ss - set to a valid point in ram
;           sp - points
;calls:     none
mInitializeStackPointer macro
   xor ax,ax         ;stack segment in RAM
   mov ss,ax
   mov sp,stackBegin ;point to top of stack
#em

;inputs:    none
;outputs:   none, interrupt table initialized
;calls:     none
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

;inputs:    none
;outputs:   none, interrupt controller initialized
;calls:     none
mInitializeInterruptController macro
   push ds

   mov ds,intControllerSegment

   mov B[intCommand1],00011011xb ;level triggered, single, ICW4 needed 
   mov B[intCommand2],00001000xb ;start address of 08h
   mov B[intCommand2],00000011xb ;auto EOI, 8086 uP

   mov B[intCommand2],11111100xb ;ignore interrupts 2-7 as they are not connected

   pop ds
#em

;inputs:    none
;outputs:   none, keyboard initialized
;calls:     int 16h - initialize keyboard
mInitializeKeyboard macro
   mov ah,04h
   int 16h
#em

;inputs:    none
;outputs:   none, LCD initialized
;calls:     int 10h - initialize display 
mInitializeDisplay macro
   xor ah,ah
   int 10h
#em

memoryGood db 0ah, ' Memory test passed', 0
memoryBad db  0ah, ' Memory test failed', 0
;inputs:    none
;outputs:   none - memory checked by storing words on both even and odd addresses.
;              If bad, it is printed on the LCD, likewise for good
;calls:     pOutputToLeds, int 21h - print string function
pTestMemory proc near
   cli               ;prevent user from using ^C
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
   sti
   ret
pTestMemory endp

splashScreen db ' ', 18 DUP '*', ' *  CEEN 4330 2013  *','*  by Josh DeWitt  *', ' ******************', 0
;inputs:    none
;outputs:   none, splash screen displayed
;calls:     int 21h - print string function
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
;outputs:   none, never returns, calls the main menu repeatedly
;calls:     all initialization macros listed above, pTestMemory, pMainMenu
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
               db 0ah, '2 - Free typing', 0ah, '3 - Memory debug', 0ah, '4 - View date/time', 0ah,
               db '5 - Set date/time', 0ah, '6 - Play song ', 0
freeTypingPrompt db '****Free Typing*****', 'ctrl + c to exit', 0ah, 0
;inputs:    none
;outputs:   none
;calls:     int 21h - print string function, int 21h - input with echo, pInputOneHex, 
;           pNewUserGuide, pLedPatternMenu, pDebugMenu, pViewDateTime, pSetDateTime, pPlaySong
pMainMenu proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset mainMenuPrompt
   mov ah,09h
   int 21h
   mov dx,0006h
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
   mov dx,offset freeTypingPrompt
   mov ah,09h
   int 21h
   mov ah,01
continueTyping:
   int 21h
   jmp continueTyping
checkMemoryDebug:
   cmp al,3
   jne checkViewDateTime
   call pDebugMenu
   jmp mainMenuComplete
checkViewDateTime:
   cmp al,4
   jne checkSetDateTime
   call pViewDateTime
   jmp mainMenuComplete
checkSetDateTime:
   cmp al,5
   jne checkPlaySong
   call pSetDateTime
   jmp mainMenuComplete
checkPlaySong:
   cmp al,6
   jne mainMenuComplete
   call pPlaySong

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
;calls:     int 21h - print string function, int 21h - input without echo
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
;calls:     int 21h - print string function, pInputOneHex, pOutputToLeds, mDelayMs
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

;inputs:    none
;outputs:   none, date and time printed to screen
;calls:     int 21h - print string function, pOutputBh, mOutputCharacter, pMakeCursorVisible, mDelayMs
viewDateTimePrompt db 0ah, '*Current date/time**', 0
pViewDateTime proc near
   push ax,bx,cx,dx,ds
   
   mov ds,romSegment
   mov dx,offset viewDateTimePrompt
   mov ah,09h
   int 21h
   
   mov ah,04h        ;read system date
   int 1ah
   mov bh,ch         ;print century
   call pOutputBh
   mov bh,cl         ;print year
   call pOutputBh
   mOutputCharacter '-'
   mov bh,dh         ;print month
   call pOutputBh
   mOutputCharacter '-'
   mov bh,dl         ;print day
   call pOutputBh
   
   mOutputCharacter ' '
   mov ah,02h        ;read system time
   int 1ah
   mov bh,ch         ;print hour
   call pOutputBh
   mOutputCharacter ':'
   mov bh,cl         ;print minute
   call pOutputBh
   mOutputCharacter ':'
   mov bh,dh
   call pOutputBh    ;print second
   
   call pMakeCursorVisible
   mDelayMs 2000
   
   pop ds,dx,cx,bx,ax
   ret
pViewDateTime endp

setDateTimePrompt db 0ah, '***Set date/time****', 0
yearPrompt   db      'Enter YYYY: ', 0
monthPrompt  db 0ah, 'Enter MM:   ', 0
dayPrompt    db 0ah, 'Enter DD:   ', 0
hourPrompt   db 0ah, 'Enter hh:   ', 0
minutePrompt db 0ah, 'Enter mm:   ', 0
secondPrompt db 0ah, 'Enter ss:   ', 0
;inputs:    none
;outputs:   none, RTC updated with the inputted information
;calls:     int 21h - print string function, pInputManyHex, int 1ah - set date function,
;           int 1ah - set time function
pSetDateTime proc near
   push ax,bx,cx,dx,ds
   
   mov ds,romSegment
   mov dx,offset setDateTimePrompt
   mov ah,09h
   int 21h
   
   mov cx,0904       ;max character allowed is 9, input 4 characters
   mov dx,offset yearPrompt
inputYear:
   int 21h
   call pInputManyHex
   push bx
   mov cx,0902       ;max character allowed is 9, input 2 characters
   mov dx,offset monthPrompt
inputMonth:
   int 21h
   call pInputManyHex
   cmp bl,12h        ;see if month is invalid
   ja inputMonth
   cmp bl,0
   jz inputMonth
   push bx
   mov dx,offset dayPrompt
inputDay:
   int 21h
   call pInputManyHex
   cmp bl,31h        ;see if day is valid
   ja inputDay
   cmp bl,00h
   jz inputDay
   
   mov dl,bl
   pop bx
   mov dh,bl
   pop bx
   mov cx,bx
   mov ah,05h
   int 1ah
   
   mov ah,09h        ;function code for print string function
   mov cx,0902       ;max character allowed is 9, input 2 characters
   mov dx,offset hourPrompt
inputHour:
   int 21h
   call pInputManyHex
   cmp bl,23h        ;see if hour is valid
   ja inputHour
   push bx
   mov dx,offset minutePrompt
inputMinute:
   int 21h
   call pInputManyHex
   cmp bl,59h        ;see if minute is valid
   ja inputMinute
   push bx
   mov dx,offset secondPrompt
inputSecond:
   int 21h
   call pInputManyHex
   cmp bl,59h
   ja inputSecond
   
   mov dh,bl
   pop bx
   mov cl,bl
   pop bx
   mov ch,bl
   mov ah,03h
   int 1ah
   
   pop ds,dx,cx,bx,ax
   ret
pSetDateTime endp

playSongPrompt db '*****Play Song******', 'Hit any key 0-f', 0ah, 'ctrl + c to exit', 0
toneArray db 191, 180, 170, 161, 152, 143, 135, 128 
          db 120, 114, 107, 101,  96,  90,  85,  80
;inputs:    none
;outputs:   none
;calls:     int 21h - print string function, mOutputCharacter, pInputOneHex, pOneIteration
pPlaySong proc near
   push ax,bx,cx,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset playSongPrompt
   mov ah,09h        
   int 21h

playAnotherNote:
   mov dx,000fh      ;normal user input, 0-f   
   call pInputOneHex
   xor bx,bx
   mov bl,al
   
   xor cx,cx
   mov cl,[offset toneArray + bx]
   mov ax,10000
   xor dx,dx
   div cx
   mov bx,ax
   
playNote:
   call pOneIteration
   dec bx
   jnz playNote
   jmp playAnotherNote
   
   pop ds,dx,cx,bx,ax
   ret
pPlaySong endp

;inputs:    cx - how many 10us waits between speaker pulses
;outputs:   none, speaker sounded
;calls:     pDelay10us
pOneIteration proc near
   push ds,cx
   
   mov ds,lcdSegment
   mov B[lcdOffset],80h
l1:
   call pDelay10us
   loop l1
   
   mov B[lcdOffset],00h
   pop cx
   push cx
l2:
   call pDelay10us
   loop l2
   
   pop cx,ds
   ret
pOneIteration endp
