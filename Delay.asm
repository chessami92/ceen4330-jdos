;inputs:    none
;outputs:   none, reuturns after 10us
pDelay10us proc near
   ;total of 51 ccs
   ;initial call takes 19ccs
   
   nop               ;3ccs
   nop
   nop
   nop

   ret               ;ret takes 20ccs
pDelay10us endp

msDelay EQU 73
;inputs:    none
;outputs:   none, continues after 1ms
pDelay1ms proc near
   ;total of 5000 ccs
   ;initial call takes 19ccs

   push cx           ;11ccs

   mov cx,msDelay    ;4ccs
tenUsDelay:
   call pDelay10us   ;51ccs
   loop tenUsDelay   ;17/5ccs

   pop cx            ;8ccs
   ret               ;ret takes 20ccs
pDelay1ms endp

;inputs:    cx - number of ms to wait
;outputs:   none, returns after cx ms
pDelayMs proc near
   push cx

delayCxMs:
   call pDelay1ms
   loop delayCxMs

   pop cx
   ret
delayMs endp

;inputs:    none
;outputs:   none, returns after 40us
mDelay40us macro
   call pDelay10us
   call pDelay10us
   call pDelay10us
   call pDelay10us
#em

;inputs:    number - how many ms to delay
;outputs:   none, returns after number ms
mDelayMs macro
   push cx
   mov cx,#1
   call pDelayMs
   pop cx
#em
