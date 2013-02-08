
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
   push es,ds,di,si,cx

   xor cx,cx
   mov es,cx         ;point to beginning of RAM
   mov di,cx
   mov ds,0f000h     ;point to beginning of ROM
   mov si,offset interruptTable

   mov cx,512        ;how many words in the IVT
   
   sti               ;allow interrupts now that IVT is initialized

   pop cx,si,di,ds,es
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
