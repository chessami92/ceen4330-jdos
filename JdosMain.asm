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

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   cli               ;make sure no interrupts while initializing

   mInitializeStackPointer
   mLoadInterruptVectorTable
   mInitializeInterruptController
   mInitializeKeyboard
   mInitializeDisplay
   mOutputSplashScreen
   
   ;int 02h TODO: dump memory to see what is the default interrupt - should be iret

   sti               ;allow interrupts now that IVT is initialized
   
   mov ax,0aaaah
   mov bl,0aah

ledFlashing:
   xor ax,0ffffh
   xor bl,0ffh
   call pOutputToLeds
   mDelayMs 200
   jmp ledFlashing
   
   ;no return because this procedure was jumped to, not called
pJdosInit endp
