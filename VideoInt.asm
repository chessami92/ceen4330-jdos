;Video service requets. 

;inputs:    al=00
;outputs:   none, screen is cleared
mScrollWindowUp macro
   
end

;inputs:    ah - function code
;outputs:   dependent on function code
int10h proc far
   cmp ah,06h
   jne done
   mScrollWindowUp

done:
   iret
int10h endp
