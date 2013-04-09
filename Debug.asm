debugMenu db '*Memory Debug Menu**', '0 - Test all memory', 0ah, '1 - Dump memory', 0ah
          db '2 - Move memory', 0ah, '3 - Edit memory', 0ah, '4 - Fill memory', 0ah, '5 - Find in memory', 0
;inputs:    
;outputs:   
pDebugMenu proc near
   push ax,dx,ds
   
   mOutputCharacter 0ah
   mov ds,romSegment
   mov dx,offset debugMenu
   mov ah,09h
   int 21h
   
   mov dx,0005h
   call pInputOneHex

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
pDumpMemory proc near
   push ax,bx,cx,ds,si
   
   mov ds,romSegment
   mov dx,offset dumpMemoryHeader
   mov ah,09h
   int 21h
   
   call pPromptForSegment
   push bx
   call pPromptForOffset
   mov si,bx
   
   mov dx,offset toolTip
   int 21h
   mDelayMs 2000
   
   pop ds
   
dumpSixteenBytes:
   mOutputCharacter 0ah
   call pOutputMemoryLocation
   mOutputCharacter ' '
   mOutputCharacter '-'
   mOutputCharacter ' '
   
   mov cx,16
   push si
printHexBytes:
   lodsb
   mov bh,al
   call pOutputBh
   cmp cx,14
   je noByteSpacer
   cmp cx,7
   je noByteSpacer
   mOutputCharacter ' '
noByteSpacer:
   loop printHexBytes
   pop si
   
   mOutputCharacter 0ah
   mov cx,16
printAsciiBytes:
   lodsb
   mConvertToPrintable al
   mOutputCharacter al
   loop printAsciiBytes
   
   call pMakeCursorVisible
   mov ah,0ah
   int 10h
   mov dx,1000h
   call pInputOneHex
   jmp dumpSixteenBytes
   
   pop si,ds,cx,bx,ax
   ret
pDumpMemory endp

moveMemoryHeader db 0ah, '****Move Memory*****', 0
sourceInformation db 'Source Information', 0ah, 0
destInformation db 0ah, 'Dest. Information', 0ah, 0
moveComplete db 0ah, '  Move Completed!  ', 0
pMoveMemory proc near
   push ax,dx,ds
   
   mov ds,romSegment
   mov dx,offset moveMemoryHeader
   mov ah,09h
   int 21h
   mov dx,offset sourceInformation
   int 21h
   
   call pPromptForSegment
   push bx
   call pPromptForOffset
   mov si,bx
   
   mov dx,offset destInformation
   int 21h
   pop ds
   call pPromptForSegment
   mov es,bx
   call pPromptForOffset
   mov di,bx
   
   call pPromptForBlockSize
   mov cx,bx
   
   cld               ;increment on string instructions
   rep movsb
   
   mov ds,romSegment
   mov dx,offset moveComplete
   int 21h
   mDelayMs 1000
   
   pop ds,dx,ax
   ret
pMoveMemory endp

editMemoryHeader db 0ah, '****Edit Memory*****', 0
pEditMemory proc near
   push ax,bx,cx,dx,ds,si,es,di
   
   mov ds,romSegment
   mov dx,offset editMemoryHeader
   mov ah,09h
   int 21h
   
   call pPromptForSegment
   push bx           ;set up ds:si and es:di for stosb and lodsb
   call pPromptForOffset
   mov si,bx
   mov di,bx
   
   mov dx,offset toolTip
   int 21h
   mDelayMs 2000
   
   pop bx
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
   call pOutputBh
   mOutputCharacter '<'
   mOutputCharacter '='
   call pMakeCursorVisible
   call pInputManyHex
   jc storeAlValue
   mov al,bl
storeAlValue:
   stosb
   jmp editBytesOfMemory
   
   pop di,es,si,ds,dx,cx,bx,ax
   ret
pEditMemory endp

fillMemoryHeader db 0ah, '****Fill Memory*****', 0
fillComplete db 0ah, '  Move Completed!  ', 0
pFillMemory proc near
   push ax,bx,cx,dx,ds,es,di
   
   mov ds,romSegment
   mov dx,offset fillMemoryHeader
   mov ah,09h
   int 21h
   
   call pPromptForSegment
   mov es,bx
   call pPromptForOffset
   mov di,bx
   call pPromptForBlockSize
   mov cx,bx
   call pPromptForData
   mov al,bl
   
   cld                  ;increment on string instructions
   rep stosb
   
   mov dx,offset fillComplete
   int 21h
   mDelayMs 1000
   
   pop di,es,ds,dx,cx,bx,ax
   ret
pFillMemory endp

findInMemoryHeader db 0ah, '***Find In Memory***', 0
foundMessage db 0ah, 'Found at ', 0
notFoundMessage db 0ah, 'Cound not find data.', 0
pFindInMemory proc near
   push ax,bx,cx,dx,ds,si
   
   mov ds,romSegment
   mov dx,offset findInMemoryHeader
   mov ah,09h
   int 21h
   
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
;outputs:   bl = block size <> 0
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
mOutputBx macro
   call pOutputBh
   xchg bh,bl
   call pOutputBh
   xchg bh,bl
#em

;inputs:    bh - hex values to display
;outputs:   none, displays bh on screen
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
;outputs:   
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
