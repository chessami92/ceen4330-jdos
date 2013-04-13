debugMenu db '*Memory Debug Menu**', '0 - Test all memory', 0ah, '1 - Dump memory', 0ah
          db '2 - Move memory', 0ah, '3 - Edit memory', 0ah, '4 - Fill memory', 0ah, '5 - Find in memory', 0
;inputs:    none
;outputs:   none, menu shown and submenu executed   
;calls:     int 21h - print string function, pInputOneHex, pTestMemory, 
;           pDumpMemory, pMoveMemory, pEditMemory, pFillMemory, pFindInMemory
pDebugMenu proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment ;print out submenu
   mov dx,offset debugMenu
   mov ah,09h
   int 21h
   
   mov dx,0005h      ;normal input, max allowed number is 5
   call pInputOneHex

   ;check to see which option was pressed, then call respective procedure
checkTestMemory:
   cmp al,0
   jne checkDumpMemory
   call pTestMemory
   jmp debugMenuComplete
checkDumpMemory:
   cmp al,1
   jne checkMoveMemory
   call pDumpMemory
   jmp debugMenuComplete
checkMoveMemory:
   cmp al,2
   jne checkEditMemory
   call pMoveMemory
   jmp debugMenuComplete
checkEditMemory:
   cmp al,3
   jne checkFillMemory
   call pEditMemory
   jmp debugMenuComplete
checkFillMemory:
   cmp al,4
   jne checkFindInMemory
   call pFillMemory
   jmp debugMenuComplete
checkFindInMemory:
   cmp al,5
   jne debugMenuComplete
   call pFindInMemory

debugMenuComplete:
   pop ds,dx,ax
   ret
pDebugMenu endp

dumpMemoryHeader db 0ah, '****Dump Memory*****', 0
toolTip db 0ah, 'Press space for next', 'or ctrl + c to exit', 0
;inputs:    none
;outputs:   none, memory dump executed until ctrl + c is pressed
;calls:     int 21h - print string function, pPromptForSegment, pPromptForOffset, mDelayMs,
;           mOutputCharacter, pOutputMemoryLocation, pOutputBh, mConvertToPrintable, 
;           pMakeCursorVisible, pInputOneHex, int 10h - refresh screen function
pDumpMemory proc near
   push ax,bx,cx,ds,si
   
   mov ds,romSegment ;print out memory dump header
   mov dx,offset dumpMemoryHeader
   mov ah,09h
   int 21h
   
   ;get the desired segment and offset
   call pPromptForSegment
   push bx           ;push bx - ds still needed to print toolTip
   call pPromptForOffset
   mov si,bx
   
   ;print instructions for user
   mov dx,offset toolTip
   int 21h
   mDelayMs 2000     ;display instructions for 2 seconds
   
   pop ds            ;restore inputted segment into ds
   
dumpSixteenBytes:
   mOutputCharacter 0ah
   call pOutputMemoryLocation
   mOutputCharacter ' '
   mOutputCharacter '-'
   mOutputCharacter ' '
   
   cld               ;increment on string functions
   mov cx,16         ;how many bytes of memory to print in hex
   push si           ;save si to be able to print in ASCII later
printHexBytes:
   lodsb             ;load current byte, print it in hex, then insert space
   mov bh,al
   call pOutputBh
   cmp cx,14
   je noByteSpacer
   cmp cx,7
   je noByteSpacer   ;do not put space in if at end of second or third line
   mOutputCharacter ' '
noByteSpacer:
   loop printHexBytes
   pop si            ;restore si to print ASCII bytes
   
   mOutputCharacter 0ah
   mov cx,16         ;how many bytes of memory to print in ASCII
printAsciiBytes:
   lodsb             ;load current byte, convert to printable character and output
   mConvertToPrintable al
   mOutputCharacter al
   loop printAsciiBytes
   
   ;make entire 16-byte memory dump visible
   call pMakeCursorVisible
   mov ah,0ah        ;refresh the screen
   int 10h
   mov dx,1000h      ;only allow user to press space
   call pInputOneHex
   jmp dumpSixteenBytes

   ;no return, only exited by crtl + c
pDumpMemory endp

moveMemoryHeader db 0ah, '****Move Memory*****', 0
sourceInformation db 'Source Information', 0ah, 0
destInformation db 0ah, 'Dest. Information', 0ah, 0
moveComplete db 0ah, '  Move Completed!  ', 0
;inputs:    none
;outputs:   none, user promted for move information, the move is executed
;calls:     int 21h - print sreen function, pPromptForSegment, pPromptForOffset, pPromptForBlockSize
pMoveMemory proc near
   push ax,dx,ds
   
   mov ds,romSegment ;print header for menu
   mov dx,offset moveMemoryHeader
   mov ah,09h
   int 21h           ;inform user this segment:offset is for source
   mov dx,offset sourceInformation
   int 21h
   
   ;get segment and offset from user
   call pPromptForSegment
   push bx           ;still need ds for printing string
   call pPromptForOffset
   mov si,bx
   
   mov dx,offset destInformation
   int 21h           ;inform user this segment:offset is for destination
   pop ds            ;fill ds now that last string print is complete
   ;get segment and offset from user
   call pPromptForSegment
   mov es,bx
   call pPromptForOffset
   mov di,bx
   
   ;get how many bytes to move from user
   call pPromptForBlockSize
   mov cx,bx
   
   cld               ;increment on string instructions
   rep movsb         ;complete the memory move
   
   mov ds,romSegment ;print out move successful message
   mov dx,offset moveComplete
   int 21h
   mDelayMs 1000     ;show message for 1 secodn
   
   pop ds,dx,ax
   ret
pMoveMemory endp

editMemoryHeader db 0ah, '****Edit Memory*****', 0
;inputs:    none
;outputs:   none, edit functionality given until ctrl + c is pressed
;calls;     int 21h - print screen function, pPromptForSegment, pPromptForOffset,
;           mDelayMs, mOutputCharacter, pOutputMemoryLocation, pOutputBh, pMakeCursorVisible,
;           pInputManyHex
pEditMemory proc near
   push ax,bx,cx,dx,ds,si,es,di
   
   mov ds,romSegment
   mov dx,offset editMemoryHeader
   mov ah,09h
   int 21h

   ;set up ds:si and es:di for stosb and lodsb
   call pPromptForSegment
   push bx           ;still need ds for printing strings           
   call pPromptForOffset
   mov si,bx
   mov di,bx
   
   mov dx,offset toolTip
   int 21h
   mDelayMs 2000     ;display toolTip for 2 seconds
   
   pop bx            ;move to ds and es now that last string has been printed
   mov ds,bx
   mov es,bx
   
   mov cx,0f02h      ;max character allowed is f, input 2 characters
   cld               ;increment on string functions
editBytesOfMemory:
   mOutputCharacter 0ah
   call pOutputMemoryLocation
   mOutputCharacter ' '
   mOutputCharacter '-'
   mOutputCharacter ' '
   lodsb
   mov bh,al
   call pOutputBh    ;print out current memory
   mOutputCharacter '<'
   mOutputCharacter '='
   call pMakeCursorVisible
   call pInputManyHex;prompt for new memory
   jc storeAlValue   ;if user presses space, do not change memory location
   mov al,bl
storeAlValue:
   stosb
   jmp editBytesOfMemory
   
   ;no return, only exited by crtl + c
pEditMemory endp

fillMemoryHeader db 0ah, '****Fill Memory*****', 0
fillComplete db 0ah, '  Fill Completed!  ', 0
;inputs:    none
;outputs:   none, user prompted for fill information, then move is executed
;calls:     int 21h - print screen function, pPromptForSegment, pPromptForOffset,
;           pPromptForBlockSize, pPromptForData, mDelayMs
pFillMemory proc near
   push ax,bx,cx,dx,ds,es,di
   
   mov ds,romSegment    ;print fill memory header
   mov dx,offset fillMemoryHeader
   mov ah,09h
   int 21h
   
   ;set up es:di cx and al for stosb
   call pPromptForSegment
   mov es,bx
   call pPromptForOffset
   mov di,bx
   call pPromptForBlockSize
   mov cx,bx
   call pPromptForData
   mov al,bl
   
   cld                  ;increment on string instructions
   rep stosb            ;perform actual fill
   
   mov dx,offset fillComplete
   int 21h
   mDelayMs 1000        ;show success message for 1 second
   
   pop di,es,ds,dx,cx,bx,ax
   ret
pFillMemory endp

findInMemoryHeader db 0ah, '***Find In Memory***', 0
foundMessage db 0ah, 'Found at ', 0
notFoundMessage db 0ah, 'Cound not find data.', 0
;inputs:    none
;outputs:   none, user prompted for find information, then memory searched and result displayed
;calls:     int 21h - print string function, pPromptForSegment, pPromptForOffset,
;           pPromptForData, pOutputMemoryLocation, mDelayMs
pFindInMemory proc near
   push ax,bx,cx,dx,ds,si
   
   mov ds,romSegment ;print out header for find menu
   mov dx,offset findInMemoryHeader
   mov ah,09h
   int 21h
   
   ;set up es:di and al for scasb
   call pPromptForSegment
   mov es,bx
   call pPromptForOffset
   mov di,bx
   call pPromptForData
   mov al,bl
   
   mov cx,0ffffh     ;search entire segment at most
   cld               ;increment di on scasb
   repne scasb       ;scan memory block for the inputted value
   
   je dataFoundInMemory
   mov dx,offset notFoundMessage
   int 21h
   jmp findInMemoryComplete
   
dataFoundInMemory:
   dec si            ;adjust because repne goes one too far
   mov dx,offset foundMessage
   int 21h
   push ds,si
   mov bx,es         ;put it in ds:si for output memory location procedure
   mov ds,bx
   mov si,di
   call pOutputMemoryLocation
   pop si,ds
   
findInMemoryComplete:
   mDelayMs 2000
   pop si,ds,dx,cx,bx,ax
   ret
pFindInMemory endp

segmentPrompt db 'Enter segment: ', 0
;inputs:    none
;outputs:   bx = segment user inputted
;calls:     int 21h - print screen function, pInputManyHex
pPromptForSegment proc near
   push ax,cx,dx,ds
   
   mov ds,romSegment
   mov dx,offset segmentPrompt
   mov ah,09h
   int 21h
   
   mov cx,0f04h      ;max character allowed is f, input 4 characters
   call pInputManyHex
   
   pop ds,dx,cx,ax
   ret
pPromptForSegment endp

offsetPrompt db 0ah, 'Enter offset:  ', 0
;inputs:    none
;outputs:   bx = segment user inputted
;calls:     int 21h - print screen function, pInputManyHex
pPromptForOffset proc near
   push ax,cx,dx,ds
   
   mov ds,romSegment
   mov dx,offset offsetPrompt
   mov ah,09h
   int 21h
   
   mov cx,0f04h      ;max character allowed is f, input 4 characters
   call pInputManyHex
   
   pop ds,dx,cx,ax
   ret
pPromptForOffset endp

blockSizePrompt db 0ah, 'Enter size:    ', 0
;inputs:    none
;outputs:   bl - block size <> 0
;           bh = 0
;calls:     int 21h - print screen function, pInputManyHex
pPromptForBlockSize proc near
   push ax,cx,dx,ds
   
inputBlockSizeAgain:
   mov ds,romSegment
   mov dx,offset blockSizePrompt
   mov ah,09h
   int 21h
   
   mov cx,0f02h      ;max character allowed is f, input 2 characters
   call pInputManyHex
   cmp bx,0
   je inputBlockSizeAgain
   
   pop ds,dx,cx,ax
   ret
pPromptForBlockSize endp

dataPrompt db 0ah, 'Enter data:    ', 0
;inputs:    none
;outputs:   bl - the data the user entered
;           bh = 0
;calls:     int 21h - print screen function, pInputManyHex
pPromptForData proc near
   push ax,cx,dx,ds
   
   mov ds,romSegment
   mov dx,offset dataPrompt
   mov ah,09h
   int 21h
   
   mov cx,0f02h      ;max character allowed is f, input 2 characters
   call pInputManyHex
   
   pop ds,dx,cx,ax
   ret
pPromptForData endp

;inputs:    bx - hex values to display
;outputs:   none, displays bx on screen
;calls:     pOutputBh
mOutputBx macro
   call pOutputBh
   xchg bh,bl
   call pOutputBh
   xchg bh,bl
#em

;inputs:    bh - hex values to display
;outputs:   none, displays bh on screen
;calls:     mHexToAscii, int 10h - print character function
pOutputBh proc
   push ax,cx,dx

   mov cl,4h      ;to easily rotate one nibble
   mov ah,09h     ;for int 10h - print character

   rol bh,cl
   mov dl,bh
   and dl,0fh
   mHexToAscii dl
   int 10h

   rol bh,cl
   mov dl,bh
   and dl,0fh
   mHexToAscii dl
   int 10h

   pop dx,cx,ax
   ret
pOutputBh endp

;inputs:    ds - segment register
;           si - offset register
;outputs:   none, ds:si printed to screen in hex
;calls:     mOutputBx, mOutputCharacter
pOutputMemoryLocation proc near
   push ax,bx,dx
   
   mov bx,ds
   mOutputBx
   
   mOutputCharacter ':'

   mov bx,si
   mOutputBx   

   pop dx,bx,ax
   ret
pOutputmemoryLocation endp
