
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

   xor cx,cx
   mov es,cx         ;point to beginning of RAM
   mov di,cx
   mov ds,0f000h     ;point to beginning of ROM
   mov si,offset interruptTable

   cld               ;increment on string instructions

   mov cx,256        ;how many entries in the IVT

   mov ax,defaultInterrupt
   mov bx,0f000h

storeDefaultInformation:
   stosb             ;store IP
   xchg ax,bx
   stosb             ;store CS
   xchg ax,bx
   loop storeDefaultInformation

   xor ah,ah         ;make sure ah is cleared, otherwise address wil be wrong
storeDefinedInterrupts:
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
   push ax,ds

   mov ax,intControllerSegment
   mov ds,ax

   mov B[intCommand1],00011011xb ;level triggered, single, ICW4 needed 
   mov B[intCommand2],00001000xb ;start address of 08h
   mov B[intCommand2],00000011xb ;auto EOI, 8086 uP

   mov B[intCommand2],11111100xb ;ignore interrupts 2-7 as they are not connected

   pop ds,ax
#em

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   cli               ;make sure no interrupts while initializing

   mInitializeStackPointer
   mLoadInterruptVectorTable
   mInitializeInterruptController
   
   mov ah,04h        ;initialize the keyboard
   int 16h
   xor ah,ah         ;initialize the display
   int 05h

   sti               ;allow interrupts now that IVT is initialized

stall:
   mov ax,0AAAAh
   mov bl,0Ah
   call pOutputToLeds
   mDelayMs 1000     ;delay 1 second
   mov ax,5555h
   mov bl,05h
   call pOutputToLeds
   mDelayMs 1000     ;delay 1 second
   jmp stall

   ret               ;included for consistency, but never reached 
pJdosInit endp
