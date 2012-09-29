
; LCD D0-D3 -> PB0-PB3
; LCD D4-D7 -> PD4-PD7
; LCD BE-RS -> PA0-PA3
; Keypad R0-C3 -> PC0-PC7
; Mot -> PB4
; OpD -> PD0
; PB0 (pushbutton) -> OpE (just to drive the ammeter)

.include "m64def.inc"
.def temp = r16
;.def temp2 = r17
;.def temp3 = r18
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

.dseg

.cseg

//Not sure if default interrupt handler is necessary
jmp reset
jmp EXT_INT0 ; ext int0
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
jmp Timer0  ; Timer0 Overflow Handler

Default:
reti

reset:

	//setup stack
	ldi YH,high(RAMEND)    ;RAMEND is the  highest SRAM address
	ldi YL,low(RAMEND)     ;setting the pointers to SRAM RAMEND address
	out SPH,YH             ;setting the stack pointers SP high 
	out SPL,YL             ;setting the stack pointers SP low

	//EX_INT0	
	in temp, EIMSK
	ldi temp, (2<<ISC00)	//Set for falling edge (EXT_INT0)				
	sts EICRA, temp                       

	in temp, EIMSK                         
	ori temp, (1<<INT0)		//Enable EXT_INT0   			
	out EIMSK, temp                       
	

	//Enable global interrupts
	sei

	ldi temp, (1<<WGM01) | (1<<WGM00) | (2<<COM00) | (2<<CS00)
	/*	WGM01 + WGM00 = NO force output compare (for PWN modes)
		COM00 = Clear OC0 on Compare Match when up-counting. Set OC0 on Compare Match when downcounting.
		CS00 = Prescaler = 8
	*/
	out TCCR0, temp

	//Set OCR0, Roughly 3 x (RPS+10) = OCR0 (add 10 for ramp up)
	ldi temp, 0xA4 
	out OCR0, temp

	//Timer0 interrupt enable
	ldi temp, (1<<TOIE0)
	out TIMSK, temp  


	ser temp1
	out DDRB, temp1 ; PORTB, the data port is usually all otuputs

main: rjmp main

EXT_INT0:
reti

Timer0:
	ldi temp, 0 
	out OCR0, temp
reti