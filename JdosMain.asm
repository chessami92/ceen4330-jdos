
;inputs:    none
;outputs:   ss - set to a valid point in ram
;           sp - points
mInitializeStackPointer macro
   mov ax,1000h      ;start at highest RAM address
   mov ss,ax
   xor sp,sp         ;point to top of stack
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
    
   sti               ;allow interrupts now that IVT is initialized

   pop cx,bx,ax,si,di,ds,es
#em

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   mInitializeStackPointer

   mLoadInterruptVectorTable
     
   xor ah,ah         ;initialize the display
   int 10h
    
   ret               ;included for consistency, but never reached 
pJdosInit endp
