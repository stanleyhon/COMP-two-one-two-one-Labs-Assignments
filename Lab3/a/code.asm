.include "m64def.inc"
.def temp =r16
.def counter=r21
.def increment=r20

.equ HIGH_LEDS = 0b11110000
.equ LOW_LEDS = 0b00001111



jmp RESET
.org INT0addr ; INT0addr is the address of EXT_INT0
jmp EXT_INT0
.org INT1addr ; INT1addr is the address of EXT_INT1
jmp EXT_INT1
RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ser temp
out DDRC, temp
clr temp
out PORTC, temp
out DDRD, temp
out PORTD, temp
ldi temp, (2 << ISC10) | (2 << ISC00)
sts EICRA, temp
in temp, EIMSK
ori temp, (1<<INT0) | (1<<INT1)
out EIMSK, temp
sei
jmp main
EXT_INT0:
push temp
in temp, SREG
push temp
add counter, increment
mov temp, counter
out PORTC, temp
pop temp
out SREG, temp
pop temp
reti
EXT_INT1:
push temp
in temp, SREG
push temp
sub counter, increment
mov temp, counter
out PORTC, temp
pop temp
out SREG, temp
pop temp
reti
main: ; main - does nothing but increment a counter
ldi increment, 1
ldi counter, 0
clr temp
loop:
inc temp
rjmp loop
