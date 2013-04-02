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

splashScreen db 20 DUP '*', '*  CEEN 4330 2013  *','*  by Josh DeWitt  *', 20 DUP '*', 0
mOutputSplashScreen macro
   push ax,dx,ds
   
   mov ah,09h
   mov ds,romSegment
   mov dx,offset splashScreen
   int 21h
   
   pop ds,dx,ax
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
   call pOutputToLeds
   mov si,[bx]       ;save memory data

   mov [bx],cx
   cmp cx,[bx]
   jne memoryTestFailed
   mov [bx],dx
   cmp dx,[bx]
   jne memoryTestFailed
   mov [bx],si       ;restore memory data
   dec bx
   jnc checkRam

   mov dx,offset memoryGood
   jmp displayTestResult

memoryTestFailed:
   mov dx,offset memoryBad

displayTestResult:
   mov ah,09h
   mov ds,romSegment
   int 21h
   pop si,ds,dx,cx,bx,ax
   ret
pTestMemory endp

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   xor ax,ax
   xor bx,bx
   xor cx,cx
   xor dx,dx

   mInitializeStackPointer
   mLoadInterruptVectorTable
   mInitializeInterruptController
   mInitializeKeyboard
   mInitializeDisplay
   call pTestMemory
   mOutputSplashScreen
   
   ;int 02h TODO: dump memory to see what is the default interrupt - should be iret

   sti               ;allow interrupts now that IVT is initialized
   
   mov bx,0aaaah
   mov al,0aah

ledFlashing:
   xor bx,0ffffh
   xor al,0ffh
   call pOutputToLeds
   mDelayMs 200
   jmp ledFlashing
   
   ;no return because this procedure was jumped to, not called
pJdosInit endp
