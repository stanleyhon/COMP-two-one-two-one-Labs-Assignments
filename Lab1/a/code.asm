;unsigned int a, b;
;void main(void){
;   while(a!=b){
;      if(a>b){
;       a=a-b;
;      else
;         b=b-a;
;      }
;   }
;}

.include "m64def.inc"
.def a_high =r16 
.def a_low =r17
.def b_high =r18
.def b_low =r19

; Theoretically it should look like
; 0000 0001 0000 0010
; which represents 257 
ldi a_high, high (6969)
ldi a_low, low (6969)

; Theoretically it should look like
; 0000 0001 0000 0001
; which represents 256
ldi b_high, high (1)
ldi b_low, low (1)

while_start: cp a_low, b_low
cpc a_high, b_high
breq while_end ; CHECK FOR EQUALITY

   cp a_low, b_low
   cpc a_high, b_high
      brlt skip_if ; if A < B, this loop happens
      sub b_low, a_low
      sbc b_high, a_high
      jmp skip_else

skip_if: sub a_low, b_low ; if A > B, this loop happens instead
sbc a_high, b_high
skip_else: jmp while_start
while_end: jmp end

end: jmp end
