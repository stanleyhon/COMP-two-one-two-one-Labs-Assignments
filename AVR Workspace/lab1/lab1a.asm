;unsigned int a, b;
;void main(void){
;   while(a!=b){
;      if(a>b){
;	     a=a-b;
;      else
;         b=b-a;
;      }
;   }
;}

.include "m64def.inc"
.def a =r16 
.def b =r17
ldi a, 1
ldi b, 10 

while_start: cp a, b
breq while_end

cp a, b
brlt skip_if
sub a, b
jmp skip_else

skip_if: sub b, a
skip_else: jmp while_start
while_end: jmp end

end: jmp end
