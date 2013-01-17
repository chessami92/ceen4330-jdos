;Real time clock functions

;inputs:    none
;outputs:   ch - hours
;           cl - minutes
;           dh - seconds
;           dl - 01 for daylight savings, 00 otherwise
;           cf - 0 if clock operating, otherwise 1
mReadClockTime macro
   
endm

;inputs:    ch - hours
;           cl - minutes
;           dh - seconds
;           dl - 01 for daylight savings, 00 otherwise
;outputs:   none
mSetClockTime macro

endm

;inputs:    none
;outputs:   ch - century (19 or 20)
;           cl - year
;           dh - month
;           dl - day
;           cf - 0 if clock operating, otherwise 1
mReadClockDate macro

endm

;inputs:    ch - century
;           cl - year
;           dh - month
;           dl - day
;outputs:   none
mSetClockDate macro

endm

;inputs:    ah - function code
;outputs:   depends on function
int1Ah proc far

   iret 
int1Ah endp
