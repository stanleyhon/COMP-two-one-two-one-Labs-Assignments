// Cabling:
// KEYPAD      -> PD0-PD7
// LCD         -> PC0-PC7
// LCD CONTROL -> PA0-PA4

// VERSION 0.1 SPECIFIC:
// LED0        -> PA7
// LED1        -> PA7

// Assignment Version X
// - Additional features/changes here

// Assignment Version 0.1
// - Only does basic LED proof-of-concept
.include "m64def.inc"

.def temp = r16
.def temp2 = r17
.def del_lo = r18
.def del_hi = r19
.def counter = r20
.def counter2 = r21
.def counter3 = r22
;.def var = r23
;.def var = r24
;.def var = r25
;.def var = r26 x
;.def var = r27 x
;.def var = r28 y
;.def var = r29 y
;.def var = r30 z
;.def var = r31 z

jmp RESET
jmp EXT_INT0 ; IRQ0 Handler
jmp Default ; IRQ1 Handler
jmp Default ; IRQ2 Handler
jmp Default ; IRQ3 Handler
jmp Default ; IRQ4 Handler
jmp Default ; IRQ5 Handler
jmp Default ; IRQ6 Handler
jmp Default ; IRQ7 Handler
jmp Default ; Timer2 Compare Handler
jmp Default ; Timer2 Overflow Handler
jmp Default ; Timer1 Capture Handler
jmp Default ; Timer1 CompareA Handler
jmp Default ; Timer1 CompareB Handler
jmp Default ; Timer1 Overflow Handler
jmp Default ; Timer0 Compare Handler
jmp Timer0 ; Timer0 Overflow Handler


Default:
reti

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp

//falling edge for EXT_INT0
ldi temp, (3<<ISC00)
sts EICRA, temp

//enable EXT_INT0
in temp, EIMSK
ori temp, (1<<INT0)
out EIMSK, temp


//Start Timer0
ldi temp, (1<<TOIE0) ; =278 microseconds
out TIMSK, temp ; T/C0 interrupt enable

ldi temp,0b00000010  ; setting the TCCR0 register: the last 3 bits- 001 clock;010 clock/8....
out TCCR0,temp

sei


main:
	


	//ldi temp2, 3

	//uses temp2
	//rcall stop

end: rjmp end

//4000000 cycles/sec
//4000 cycles/ms - 4 cycles/micro sec
delayCTL: //3 cycles
	push del_lo
	push del_hi

	subi del_lo, 3
	sbci del_hi, 0

	nop
	nop
	nop

	loop:
		subi del_lo, 1
		sbci del_hi, 0 //2 cycle
	BRNE loop //2 cycles (1 cycle exit)

	nop
	pop del_hi
	pop del_lo

ret //4 cycles


delaySec:
	push del_lo
	push del_hi
	push temp2
	ldi temp2, 37
	delayloop :
		ldi del_lo, low(50000)
		ldi del_hi, high(50000)
		rcall delayCTL
		subi temp2, 1
	brne delayloop
	pop temp2
	pop del_hi
	pop del_lo
ret

delayQuartSec:
	push del_lo
	push del_hi
	push temp2
	ldi temp2, 37
	delayloop2 :
		ldi del_lo, low(12500)
		ldi del_hi, high(12500)
		rcall delayCTL
		subi temp2, 1
	brne delayloop2
	pop temp2
	pop del_hi
	pop del_lo
ret

stop:
	push temp
	in temp, SREG
	push temp
	in temp, DDRA
	push temp


	ldi temp, (1<<DDA7)
	out DDRA, temp

	delayloop3 :
		push temp2
		ser temp2

		in temp, PINA
		eor temp, temp2
		out PORTA, temp
		rcall delayQuartSec

		in temp, PINA
		eor temp, temp2
		out PORTA, temp
		rcall delayQuartSec

		in temp, PINA
		eor temp, temp2
		out PORTA, temp
		rcall delayQuartSec

		in temp, PINA
		eor temp, temp2
		out PORTA, temp
		rcall delayQuartSec


		pop temp2
		subi temp2, 1
	brne delayloop3

	
	pop temp
	out DDRA, temp
	pop temp
	out SREG, temp
	pop temp
ret



EXT_INT0:
	push temp
	in temp, SREG
	push temp
	push temp2
/*
	in temp, TIMSK
	LSR temp
	BRCS disableTimer

	ldi temp, 1<<TOIE0 ; =278 microseconds
	out TIMSK, temp ; T/C0 interrupt enable
	jmp exitInt

	disableTimer:

	ldi temp, 0<<TOIE0 ; =278 microseconds
	out TIMSK, temp ; T/C0 interrupt disable

	exitInt:

	ldi counter,0 ; clearing the counter values after counting 3597 interrupts which gives us one second
   ldi counter2,0
   ldi counter3,0
*/


	ldi temp2, 1
	rcall stop

	pop temp2
	pop temp
	out SREG, temp
	pop temp
reti


Timer0: ; Prologue starts.
push temp ; Save all conflict registers in the prologue.
in temp, SREG
push temp
in temp, DDRA
push temp
push temp2

//For testing - should alternate leds
		ldi temp, (1<<DDA7)
		out DDRA, temp2

		ser temp2
		in temp, PINA
		eor temp, temp2
		out PORTA, temp


; HOWEVER: to avoid complication of dividing by 4, we can interrupt every 1/4 of a second. 899.25 interrupts per 1/4 second
cpi counter, 99 ; counting for 99
brne notsecond
 
cpi counter2, 8 ; counting for 8
brne secondloop ; jumping into count 100

outmot: ldi counter,0 ; clearing the counter values after counting 3597 interrupts which gives us one second
        ldi counter2,0
        ldi counter3,0
     
		ldi temp, (1<<DDA7)
		out DDRA, temp2

		ser temp2
		in temp, PINA
		eor temp, temp2
		out PORTA, temp

        rjmp exit ; go to exit

notsecond: inc counter ; if it is not a second, increment the counter
           rjmp exit

secondloop: inc counter3 ; counting 100 for every 35 times := 35*100 := 3500
            cpi counter3,100
            brne exit
inc counter2
ldi counter3,0

exit:

pop temp2
pop temp
out DDRA, temp
pop temp ; Epilogue starts;
out SREG, temp ; Restore all conflict registers from the stack.
pop temp
reti ; Return from the interrupt. ; Return from the interrupt.
