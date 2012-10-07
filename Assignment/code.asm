
.include "m64def.inc"

.def temp = r16
.def temp2 = r17
.def del_lo = r18
.def del_hi = r19
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


jmp RESET ; Reset Handler
jmp noInt ; IRQ0 Handler
jmp noInt ; IRQ1 Handler
jmp noInt ; IRQ2 Handler
jmp noInt ; IRQ3 Handler
jmp noInt ; IRQ4 Handler
jmp noInt ; irq5
jmp noInt ; 6
jmp noInt ; 7
jmp noInt ; timer2
jmp noInt
jmp noInt ; timer 1
jmp noInt
jmp noInt ; timer 0 compare
jmp noInt ; timer 0 overflow

noInt:
   reti

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp


main:
	
	ldi temp2, 3

	//uses temp2
	rcall stop

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
	in temp, DDRA
	push temp

	ldi temp, (1<<DDA7)
	out DDRA, temp

	delayloop3 :
		ser temp
		out PORTA, temp
		rcall delayQuartSec

		ldi temp, 0
		out PORTA, temp
		rcall delayQuartSec

		ser temp
		out PORTA, temp
		rcall delayQuartSec

		ldi temp, 0
		out PORTA, temp
		rcall delayQuartSec



		subi temp2, 1
	brne delayloop3

	
	pop temp
	out DDRA, temp2
	pop temp
ret
