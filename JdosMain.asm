;inputs:    ax - first to store
;           bx - second to store
;           es:di - location to store
;outputs:   none
mStoreDoubleWord macro
   stosw             ;first store the offset ax
   xchg ax,bx
   stosw             ;second store the segment bx
   xchg ax,bx
#em

;inputs:    none
;outputs:   none
mLoadInterruptVectorTable macro
   push ax
   push bx
   push cx
   push es
   push di

   xor ax,ax      ;clear es:di for setting up default interrupts
   mov es,ax
   xor di,di

   ;bx:ax is the address of default: simply an iret command
   mov ax,1234h
   mov bx,5678h
   mov cx,256        ;number of interrupts

   cld               ;increment si on stosw

storeDefault:
   mStoreDoubleWord
   loop storeDefault

   mov di,40h        ;int 10h
   mov ax,1234h
   mov bx,1234h
   mStoreDoubleWord

   mov di,68h        ;int 1ah
   mov ax,1234h
   mov bx,5678h
   mStoreDoubleWord
   
   mov di,84h        ;int 21h
   mov ax,1234h
   mov bx,5678h
   mStoreDoubleWord

   sti               ;allow interrupts now that IVT is initialized

   pop di
   pop es
   pop cx
   pop bx
   pop ax
#em

;inputs:    none
;outputs:   ss - set to a valid point in ram
;           sp - points
mInitializeStackPointer macro
   mov ax,1000h      ;start at highest RAM address
   mov ss,ax
   xor sp,sp         ;point to top of stack
#em

;inputs:    none
;outputs:   none, sets up display for use
mInitializeDisplay macro
   and al,11h
#em

;First point of entry for the microprocessor.
;inputs:    none
;outputs:   none
pJdosInit proc far
   mInitializeStackPointer

   mLoadInterruptVectorTable
     
   mInitializeDisplay
    
   ret               ;included for consistency, but never reached 
pJdosInit endp
