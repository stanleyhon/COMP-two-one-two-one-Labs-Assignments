.include "m64def.inc"
.def a =r16 ; define a to be register r16
.def b =r17
.def c =r18
.def d =r19
.def e =r20
main: ; main is a label
ldi a, 10 ; load 10 into r16
ldi b, -20
mov c, a ; copy the value of r16 into r18
add c, b ; add r18 and r17 and store the result in r18
mov d, a
sub d, b ; subtract r17 from r19 and store the result in r19
lsl c ; refer to AVR Instruction Set for the semantics of
asr d ; lsl and asr
mov e, c
add e, d
loop:
inc r21 ; increase the value of r21 by 1
rjmp loop ; jump to loop
