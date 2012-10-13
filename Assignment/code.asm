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

// Assignment Version 0.2a - Stanley
// - Added functional LCD
// - Working on printing query string

.def temp = r16
.def temp2 = r17
.def orig = r17 // dupe used for writeNumber
.def del_lo = r18
.def del_hi = r19
.def counter = r20
.def counter2 = r21
.def counter3 = r22
.def data = r23 // Used in LCD Functions
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


// LCD FUNCTION RELATED 

;LCD protocol control bits
.equ LCD_RS = 3
.equ LCD_RW = 1
.equ LCD_E = 2
;LCD functions
.equ LCD_FUNC_SET = 0b00110000
.equ LCD_DISP_OFF = 0b00001000
.equ LCD_DISP_CLR = 0b00000001
.equ LCD_DISP_ON = 0b00001100
.equ LCD_ENTRY_SET = 0b00000100
.equ LCD_ADDR_SET = 0b10000000


.equ LCD_GO_TO_START_2ND_LINE = 0b11000000 // 0100 0000 is 41
										   // 8th bit is meant to be a 1
										   // lcd_write_com automatically writes 0,0 to rs rw


;LCD function bits and constants
.equ LCD_BF = 7
.equ LCD_N = 3
.equ LCD_F = 2
.equ LCD_ID = 1
.equ LCD_S = 0
.equ LCD_C = 1
.equ LCD_B = 0
.equ LCD_LINE1 = 0
.equ LCD_LINE2 = 0x40

Default:
reti

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp


//Initialise the LCD
rcall lcd_init

// Clear the display
ldi data, LCD_DISP_CLR
rcall lcd_write_com ; Clear Display
rcall lcd_wait_busy ; Wait until the LCD is ready


//falling edge for EXT_INT0
ldi temp, (2<<ISC00)
sts EICRA, temp

//enable EXT_INT0
in temp, EIMSK
ori temp, (1<<INT0)
out EIMSK, temp

//led out
in temp, DDRA
ori temp, (1<<DDA7)
out DDRA, temp

//motor out
ldi temp, (1<<DDB4)
out DDRB, temp

//Timer enable (normally enabled on EXT_INT0
//ldi temp, (1<<TOIE0) ; =278 microseconds
//out TIMSK, temp ; T/C0 interrupt enable

ldi temp, (1<<WGM01) | (1<<WGM00) | (2<<COM00) | (2<<CS00)
/*	WGM01 + WGM00 = NO force output compare (for PWN modes)
COM00 = Clear OC0 on Compare Match when up-counting. Set OC0 on Compare Match when downcounting.
CS00 = Prescaler = 8
*/
out TCCR0, temp

sei

// String definitions for query strings
number_of_stations_query: .db "max stat: "
name_station_query: .db "name stat "


main:

	rcall lcd_wait_busy

	ldi data, 10
	rcall lcd_write_name_station_in_data

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


	//make sure PB4 is out
	in temp, DDRB
	ori temp, (1<<DDB4)
	out DDRB, temp

	in temp, TIMSK
	LSR temp
	BRCS disableTimer

	enableTimer:

		ldi temp, (1<<TOIE0) ; =278 microseconds
		out TIMSK, temp ; T/C0 interrupt enable

		ldi counter,0 ; clearing the counter values after counting 3597 interrupts which gives us one second
		ldi counter2,0
		ldi counter3,0

		//set motor
		ldi temp, 100
		out OCR0, temp

		jmp exitInt

	disableTimer:

		ldi temp, (0<<TOIE0) ; =278 microseconds
		out TIMSK, temp ; T/C0 interrupt disable

		//set motor
		ldi temp, 0
		out OCR0, temp

		in temp, DDRA
		push temp

		ldi temp, (1<<DDA7)
		out DDRA, temp

		//TODO outs 0 to PORTA (should only out to pin7)
		clr temp
		out PORTA, temp

		pop temp
		out DDRA, temp

	exitInt:

	pop temp2
	pop temp
	out SREG, temp
	pop temp
reti


Timer0: ; Prologue starts.
push temp ; Save all conflict registers in the prologue.
in temp, SREG
push temp
push temp2

; HOWEVER: to avoid complication of dividing by 4, we can interrupt every 1/4 of a second. 899.25 interrupts per 1/4 second
cpi counter, 99 ; counting for 99
brne notsecond
 
cpi counter2, 8 ; counting for 8
brne secondloop ; jumping into count 100

outmot: ldi counter,0 ; clearing the counter values after counting 3597 interrupts which gives us one second
        ldi counter2,0
        ldi counter3,0

		in temp, DDRA
		push temp

		ser temp2

				//make sure PA7 is out
		ldi temp,(1<<DDA7) | (3<<DDA0)
		out DDRA, temp

		in temp, PINA
		eor temp, temp2
		out PORTA, temp
                          
		pop temp
		out DDRA, temp

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
pop temp ; Epilogue starts;
out SREG, temp ; Restore all conflict registers from the stack.
pop temp
reti ; Return from the interrupt. ; Return from the interrupt.

/********************************************************************/
/********** LCD FUNCTIONS BELOW THIS POINT **************************/
/********************************************************************/

// Modifications: - Changed PORTD -> PORTC interface with LCD

; Function delay: Pass a number in registers r18:r19 to indicate how many microseconds
; must be delayed. Actual delay will be slightly greater (~1.08us*r18:r19).
; r18:r19 are altered in this function.
; Code is omitted
;Function lcd_init Initialisation function for LCD.
lcd_init:
	ser temp
	out DDRC, temp ; PORTC, the data port is usually all otuputs
	out DDRA, temp ; PORTA, outputs
	ldi del_lo, low(15000)
	ldi del_hi, high(15000)
	rcall delayCTL ; delay for > 15ms
	; Function set command with N = 1 and F = 0
	ldi data, LCD_FUNC_SET | (1 << LCD_N)
	rcall lcd_write_com ; 1st Function set command with 2 lines and 5*7 font
	ldi del_lo, low(4100)
	ldi del_hi, high(4100)
	rcall delayCTL ; delay for > 4.1ms
	rcall lcd_write_com ; 2nd Function set command with 2 lines and 5*7 font
	ldi del_lo, low(100)
	ldi del_hi, high(100)
	rcall delayCTL ; delay for > 100us
	rcall lcd_write_com ; 3rd Function set command with 2 lines and 5*7 font
	rcall lcd_write_com ; Final Function set command with 2 lines and 5*7 font
	rcall lcd_wait_busy ; Wait until the LCD is ready
	ldi data, LCD_DISP_OFF
	rcall lcd_write_com ; Turn Display off
	rcall lcd_wait_busy ; Wait until the LCD is ready
	ldi data, LCD_DISP_CLR
	rcall lcd_write_com ; Clear Display
	rcall lcd_wait_busy ; Wait until the LCD is ready
	; Entry set command with I/D = 1 and S = 0
	ldi data, LCD_ENTRY_SET | (1 << LCD_ID)
	rcall lcd_write_com ; Set Entry mode: Increment = yes and Shift = no
	rcall lcd_wait_busy ; Wait until the LCD is ready
	; Display on command with C = 0 and B = 1
	ldi data, LCD_DISP_ON | (1 << LCD_C)
	rcall lcd_write_com ; Trun Display on with a cursor that doesn't blink
ret

//Function lcd_write_com: Write a command to the LCD. The data reg stores the value to be written.
lcd_write_com:
	out PORTC, data ; set the data port's value up
	clr temp
	out PORTA, temp ; RS = 0, RW = 0 for a command write
	nop ; delay to meet timing (Set up time)
	sbi PORTA, LCD_E ; turn on the enable pin
	
	nop ; delay to meet timing (Enable pulse width)
	nop
	nop
	
	cbi PORTA, LCD_E ; turn off the enable pin
	
	nop ; delay to meet timing (Enable cycle time)
	nop
	nop
ret

;Function lcd_write_data: Write a character to the LCD. The data reg stores the value to be written.
lcd_write_data:
	out PORTC, data ; set the data port's value up
	ldi temp, 1 << LCD_RS
	out PORTA, temp ; RS = 1, RW = 0 for a data write
	nop ; delay to meet timing (Set up time)
	sbi PORTA, LCD_E ; turn on the enable pin

	nop ; delay to meet timing (Enable pulse width)
	nop
	nop

	cbi PORTA, LCD_E ; turn off the enable pin

	nop ; delay to meet timing (Enable cycle time)
	nop
	nop
ret

;Function lcd_wait_busy: Read the LCD busy flag until it reads as not busy.
lcd_wait_busy:
	clr temp
	out DDRC, temp ; Make PORTC be an input port for now
	out PORTC, temp
	ldi temp, 1 << LCD_RW
	out PORTA, temp ; RS = 0, RW = 1 for a command port read

	busy_loop:
		nop ; delay to meet timing (Set up time / Enable cycle time)
		sbi PORTA, LCD_E ; turn on the enable pin
		nop ; delay to meet timing (Data delay time)
		nop
		nop
		in temp, PINC ; read value from LCD
		cbi PORTA, LCD_E ; turn off the enable pin\]
		sbrc temp, LCD_BF ; if the busy flag is set
	rjmp busy_loop ; repeat command read

	clr temp ; else
	out PORTA, temp ; turn off read mode,
	ser temp
	out DDRC, temp ; make PORTD an output port again
ret ; and return


// Writes "Please type the maximum number of stations: " to the screen on two lines
// 44 chars
lcd_write_number_of_stations_query:
	push temp // keep track of how many we've written
	ldi temp, 10
	push data
	push ZL
	push ZH

	// According to 
	// http://www.cse.unsw.edu.au/~cs2121/ExampleCode/lcd.asm
	// we need to multiply it by 2...
	ldi ZL, low(number_of_stations_query << 1) 
	ldi ZH, high(number_of_stations_query << 1)

	write_another:
		lpm data, Z+
		push temp
		rcall lcd_wait_busy
		rcall lcd_write_data
		pop temp
		dec temp
	brne write_another

	pop ZH
	pop ZL
	pop data
	pop temp
ret

// Put a number into data, writes 
// "name stat X:"
lcd_write_name_station_in_data:
	push temp // keep track of how many we've written
	ldi temp, 10
	push data
	push ZL
	push ZH

	// According to 
	// http://www.cse.unsw.edu.au/~cs2121/ExampleCode/lcd.asm
	// we need to multiply it by 2...
	ldi ZL, low(name_station_query << 1) 
	ldi ZH, high(name_station_query << 1)

	write_another2:
		lpm data, Z+
		push temp
		rcall lcd_wait_busy
		rcall lcd_write_data
		pop temp
		dec temp
	brne write_another2

	pop ZH
	pop ZL
	pop data

	// Write the number
	rcall lcd_wait_busy
	mov temp, data
	rcall writeNumber

	// write the colon
	ldi data, ':'
	rcall lcd_wait_busy
	rcall lcd_write_data


	pop temp
ret
	
; == Takes in (in 'temp'), an unsigned 8 bit number and prints it.

writeNumber:
	push temp  ; holds the current most significant digit
	push temp2 ; holds a copy of the original value
	push orig  ; holds the original value

	mov temp2, temp ; 
	mov orig, temp ; 

	// 100
	
	cpi orig, 100 ; if value < 100, skip
	brlo skipHundreds

	clr data ;data = 0
	ldi temp, 100 ; MSD temp = 100

	hundredLoop:

	cp temp2, temp ; while temp2 >= 100
	brlo exitHundreds

	sub temp2, temp ;temp2 -= temp
	inc data
	rjmp hundredLoop
	exitHundreds:


	subi data, (-'0')
    rcall lcd_wait_busy
	rcall lcd_write_data

	skipHundreds:

	// 10s
	cpi orig, 10 ; if data < 10, skip
	brlo skip_dozens

	ldi temp, 10 ; get 10s
	clr data ; data = 0

	dozens_loop:

	cp temp2, temp ; while temp2 >= 10
	brlo exit_dozens

	sub temp2, temp
	inc data

	rjmp dozens_loop
	exit_dozens:


	subi data, (-'0')
    rcall lcd_wait_busy
	rcall lcd_write_data

	skip_dozens:

	// 1
	ldi temp, 1 ; get 10s
	ldi data, 0
	onesLoop:
	cp temp2, temp ; while temp2 >= 1
	brlo exit_ones

	sub temp2, temp
	inc data

	rjmp onesLoop
	exit_ones:

	subi data, (-'0')
    rcall lcd_wait_busy
	rcall lcd_write_data


	pop orig
	pop temp2
  	pop temp

ret

/********************************************************************/
/********** LCD FUNCTIONS ABOVE THIS POINT **************************/
/********************************************************************/
