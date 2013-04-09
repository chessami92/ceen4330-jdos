;Real time clock functions

clockWriteBit EQU 80h
clockReadBit EQU 40h

;inputs:    ah - function code
;outputs:   depends on function
int1ah proc far
   push ds
   
   mov ds,clockSegment
checkReadClockTime:
   cmp ah,02h
   jne checkSetClockTime
   call pReadClockTime
   jmp timeInterruptComplete
checkSetClockTime:
   cmp ah,03h
   jne checkReadClockDate
   call pSetClockTime
   jmp timeInterruptComplete
checkReadClockDate:
   cmp ah,04h
   jne checkSetClockDate
   call pReadClockDate
   jmp timeInterruptComplete
checkSetClockDate:
   cmp ah,05h
   jne timeInterruptComplete
   call pSetClockDate
   jmp timeInterruptComplete

timeInterruptComplete:
   pop ds
   iret 
int1Ah endp

;inputs:    ds - segment of RTC
;outputs:   ch - hours
;           cl - minutes
;           dh - seconds
pReadClockTime proc near
   mov B[control],clockReadBit 

   mov ch,[hour]
   and ch,3fh
   mov cl,[minute]
   and cl,7fh
   mov dh,[second]
   and dh,7fh
   
   mov B[control],00h
   ret
pReadClockTime endp

;inputs:    ds - segment of RTC
;           ch - hours
;           cl - minutes
;           dh - seconds
;outputs:   none
pSetClockTime proc near
   mov B[control],clockWriteBit

   and ch,3fh
   mov [hour],ch
   and cl,7fh
   mov [minute],cl
   and dh,7fh
   mov [second],dh

   mov B[control],00h
   ret
pSetClockTime endp

;inputs:    ds - segment of RTC
;outputs:   ch - century (19 or 20)
;           cl - year
;           dh - month
;           dl - date
;           cf - 0 if clock operating, otherwise 1
pReadClockDate proc near
   mov B[control],clockReadBit 

   mov ch,[century]
   mov cl,[year]
   mov dh,[month]
   and dh,1fh
   mov dl,[date]
   and dl,3fh
   
   mov B[control],00h
   ret
pReadClockData endp

;inputs:    ds - segment of RTC
;           ch - century
;           cl - year
;           dh - month
;           dl - date
;outputs:   none
pSetClockDate proc near
   mov B[control],clockWriteBit
   
   mov [century],ch
   mov [year],cl
   and dh,1fh
   mov [month],dh
   and dl,3fh
   mov [date],dl

   mov B[control],00h
   ret
pSetClockDate endp
