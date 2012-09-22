.include "m64def.inc"

.def temp1 = r16
; def temp2 = r17
;.def var = r18
;.def var = r19
;.def var = r20
;.def var = r21
;.def var = r22
;.def var = r23
;.def var = r24
;.def var = r25
;.def var = r26 x
;.def var = r27 x
;.def var = r28 y
;.def var = r29 y
;.def var = r30 z
;.def var = r31 z

jmp reset 
jmp Timer0 ; interrupt handler for timer0 (overflow)

.dseg

motorSpeed: .byte 1

.cseg

reset:
	ldi temp1, low(RAMEND)
	out SPL, temp1
	ldi temp1, high(RAMEND)
	out SPH, temp1 
/*
   ser temp1

   ldi temp1, (2 << ISC10) | (2 << ISC00) ;setting the interrupts for falling edge
	sts EICRA, temp1 ;storing them into EICRA
	in temp1, EIMSK ;taking the values inside the EIMSK
	ori temp1, (1<<INT0) | (1<<INT1) ; oring the values with INT0 and INT1
	out EIMSK, temp1 ; enabling interrput0 and interrupt1

   sei // enable global? interrupts

	ldi ZL, low(motorSpeed)
	ldi ZH, high(motorSpeed)

	ldi temp1, 20
	st Z, temp1
*/
	ldi temp1, 0b011011112
	out TCCR0, temp1
   
	ldi temp1,           
	out OCR0, temp1

	ldi temp1, 1<<TOIE0       ; =278 microseconds
	out TIMSK, temp1          ; T/C0 interrupt enable

   ser temp1

	out DDRB, temp1 ; PORTB, the data port is usually all otuputs

chill:
	rjmp chill

Timer0:
	reti
