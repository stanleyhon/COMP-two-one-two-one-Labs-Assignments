; COMP2121 Lab 3
; Randal Grant
; 10/5/12

; LCD D0-D3 -> PB0-PB3
; LCD D4-D7 -> PD4-PD7
; LCD BE-RS -> PA0-PA3
; Keypad R0-C3 -> PC0-PC7
; Mot -> PB4
; OpD -> PD0
; PB0 (pushbutton) -> OpE (just to drive the ammeter)
; 

.include "m64def.inc"
.def temp =r16
.def data =r17
.def del_lo = r18
.def del_hi = r19

.def counter =r20
.def counter2= r21
.def counter3=r22

.def row =r23
.def col =r24
.def mask =r25
.def temp2 =r26 ;XL

.def input_enabled = r27 ; XH whether input is enabled, boolean flag

.def temp_low = r28 ; taking the place of Y (required for delay function.. had to fit all the registers in)
.def temp_high = r29

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


.equ PORTCDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

.dseg

; == Define Variables in data space ==
; note: rps not rpm, initial misunderstanding of spec

var_numinterrupts: .byte 1 ; byte, how many interrupts were detected in the quartersecond
var_motrpm: .byte 1 ; byte, how much the user has input to run the motor at
var_realrpm: .byte 1 ; byte, the actual detected RPS
var_adjustedrpm: .byte 1 ; byte, the motrpm adjusted by the realrpm to mroe closely match the output

.cseg
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


; == Lab 3 Main Function ==  
      str_label: .db "Set RPS:  "
     .equ LENGTH = 9
      str_label2: .db "Real RPS: "
    .equ LENGTH2 = 10

reset:
	ldi YH,high(RAMEND)    ;RAMEND is the  highest SRAM address
	ldi YL,low(RAMEND)     ;setting the pointers to SRAM RAMEND address
	out SPH,YH             ;setting the stack pointers SP high 
	out SPL,YL             ;setting the stack pointers SP low

	ldi temp, PORTCDIR ; columns are outputs, rows are inputs
	out DDRC, temp
	ser temp

	ldi input_enabled, 1





	; enabling interrupt
	ldi temp, (2 << ISC10) | (2 << ISC00) ;setting the interrupts for falling edge
	sts EICRA, temp                       ;storing them into EICRA 
	in temp, EIMSK                        ;taking the values inside the EIMSK  
	ori temp, (1<<INT0)      			; oring the values with INT0
	out EIMSK, temp                       ; enabling interrupt0
	sei

	ldi ZL, low(var_motrpm)
	ldi ZH, high(var_motrpm)
	
	ldi temp, 20
	st Z, temp ; initial RPM = 20

	ldi ZL, low(var_numinterrupts)
	ldi ZH, high(var_numinterrupts)
	ldi temp, 0
	st Z, temp ; set num_interrupts = 0

	; set up PWM and timer registers
	ldi temp, 0b01101010
	;no Force Output Compare (7=0)
	;-Fast PWM (6=1, 3=1)
	;Set OC0 when upcounting, (5=1,4=1)
	; prescaling value = 8(2,1,0 = 010)
	; Prescaling value=8  ;256*8/7.3728( Frequency of the clock 7.3728MHz, for the overflow it should go for 256 times)
	out TCCR0, temp
	ldi temp, 0xA4 ; 
	out OCR0, temp ;output compare, basically the pulse width in cycles (?)


	ldi temp, 1<<TOIE0       ; =278 microseconds
	out TIMSK, temp          ; T/C0 interrupt enable


	rcall lcd_init

main: ; Scan the keypad and act on the key that was pressed. Also updates the main screen.

ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop:
	out PORTC, mask ; set column to mask value
	; (sets column 0 off)
	ldi temp, 0xFF ; implement a delay so the
	; hardware can stabilize (255*3? cycles)
	delay_keypad:
		dec temp
	brne delay_keypad

	in temp, PINC ; read PORTB
	andi temp, ROWMASK ; read only the row bits
	cpi temp, 0xF ; check if any rows are grounded
	breq nextcol ; if not go to the next column
	ldi mask, INITROWMASK ; initialise row check
	clr row ; initial row
	rowloop:
		mov temp2, temp
		and temp2, mask ; check masked bit
		brne skipconv ; if the result is non-zero,
		; we need to look again
		rcall convert ; if bit is clear, convert the bitcode


		skipconv:
			inc row ; else move to the next row
			lsl mask ; shift the mask to the next bit
	jmp rowloop
	nextcol:
	cpi col, 3 ; check if were on the last column
	breq nothing_pressed ; if so, no buttons were pushed,
	; so skip to nothing_pressed


	sec ; else shift the column mask:
	; We must set the carry bit
	rol mask ; and then rotate left by a bit,
	; shifting the carry into
	; bit zero. We need this to make
	; sure all the rows have
	; pull-up resistors
	inc col ; increment column value
jmp colloop ; and check the next column

; convert function converts the row and column given to a
; binary number and also outputs the value to PORTC.
; Inputs come from registers row and col and output is in
; temp.
convert:
	cpi col, 3 ; if column is 3 we have a letter
	breq letters
	cpi row, 3 ; if row is 3 we have a symbol or 0
	breq symbols
	mov temp, row ; otherwise we have a number (1-9)
	lsl temp ; temp = row * 2
	add temp, row ; temp = row * 3
	add temp, col ; add the column address
	; to get the offset from 1
	inc temp ; add 1. Value of switch is
	; row*3 + col + 1.
jmp convert_end
letters:
	ldi temp, 0xA
	add temp, row ; increment from 0xA by the row value
	jmp convert_end
symbols:
	cpi col, 0 ; check if we have a star
	breq star
	cpi col, 1 ; or if we have zero
	breq zero
	ldi temp, 0xF ; we'll output 0xF for hash
	jmp convert_end
star:
	ldi temp, 0xE ; we'll output 0xE for star
	jmp convert_end
zero:
	clr temp ; set to zero

convert_end: ;value been converted, try to act on this

cpi temp, 0
breq nothing_pressed

; stop if input disabled
cpi input_enabled, 1
brlt output_lcd

;disable input
ldi input_enabled, 0

cpi temp, 1
breq one_pressed
cpi temp, 2
breq two_pressed
cpi temp, 3
breq three_pressed
cpi temp, 4
breq four_pressed


rjmp output_lcd

nothing_pressed: ;nothing: re-enable input
ldi input_enabled, 1
rjmp output_lcd

one_pressed:	; 1: increase rpm by 5 (up to 80)

ldi ZL, low(var_motrpm)
ldi ZH, high(var_motrpm)

ld temp, Z


cpi temp, 80
brge output_lcd ; exit if motrpm >= 80
subi temp, -5 ; subtract -5 from rpm (i.e. increase by5)
st Z, temp ; save motrpm

ldi ZL, low(var_adjustedrpm) ; adjustedrpm appropriately
ldi ZH, high(var_adjustedrpm)

st Z, temp

rjmp output_lcd

two_pressed:	; 2: decrease rpm by 5 (down to 20)

ldi ZL, low(var_motrpm)
ldi ZH, high(var_motrpm)

ld temp, Z

cpi temp, 21
brlo output_lcd ; exit if motrpm < 21
subi temp, 5 ; subtract 5 from rpm
st Z, temp ; save motrpm

ldi ZL, low(var_adjustedrpm) ; adjustedrpm appropriately
ldi ZH, high(var_adjustedrpm)

st Z, temp


rjmp output_lcd 

three_pressed:; 3: stop motor
ldi ZL, low(var_motrpm)
ldi ZH, high(var_motrpm)
ldi temp, 0
st Z, temp

ldi ZL, low(var_adjustedrpm) ; adjustedrpm appropriately
ldi ZH, high(var_adjustedrpm)

st Z, temp

rjmp output_lcd

four_pressed: ; 4: reset to 20rpm

ldi ZL, low(var_motrpm)
ldi ZH, high(var_motrpm)
ldi temp, 20
st Z, temp

ldi temp, 35 ; we need about 35 'power' by default to get it to jump at 20rpm

ldi ZL, low(var_adjustedrpm) ; adjustedrpm appropriately
ldi ZH, high(var_adjustedrpm)

st Z, temp

rjmp output_lcd

output_lcd: ; draws the screen
	; write number to lcd
	rcall lcd_init

	; Display the screen in the format:
	; Set RPM: <motrpm>
	; Real RPM: <realrpm>(<adjustedrpm>)

	; ==== Show Set RPM ====

	; Print the string
	ldi temp, LENGTH
	ldi ZL, low(str_label<<1)
	ldi ZH, high(str_label<<1)
	label_loop_start:
		lpm data, Z+

		rcall lcd_wait_busy
		rcall lcd_write_data

		dec temp
		brne label_loop_start


	; Call print_unsigned
	ldi ZL, low(var_motrpm)
	ldi ZH, high(var_motrpm)
	ld temp, Z
	rcall print_unsigned

	
	; == Set insertion to Line 2 ==
	rcall lcd_wait_busy
	ldi data, LCD_ADDR_SET | LCD_LINE2
	rcall lcd_write_com


	; Print the string
	ldi temp, LENGTH2
	ldi ZL, low(str_label2<<1)
	ldi ZH, high(str_label2<<1)
	label2_loop_start:
		lpm data, Z+

		rcall lcd_wait_busy
		rcall lcd_write_data

		dec temp
		brne label2_loop_start


	; Call print_unsigned

	ldi ZL, low(var_realrpm)
	ldi ZH, high(var_realrpm)
	ld temp, Z
	rcall print_unsigned


	ldi data, '('
	rcall lcd_wait_busy
	rcall lcd_write_data

	ldi ZL, low(var_adjustedrpm)
	ldi ZH, high(var_adjustedrpm)
	ld temp, Z
	rcall print_unsigned


	ldi data, ')'
	rcall lcd_wait_busy
	rcall lcd_write_data

	; === End ===

	; Set the OCR0
	; scaling value.



	ldi ZL, low(var_adjustedrpm)
	ldi ZH, high(var_adjustedrpm)
	ld temp, Z
	ldi temp2, 3
	mul temp, temp2 ;TODO change to Word width
	out OCR0, r0


	; = Loop back to Main =


jmp main


; === EXTERNAL INTERRUPT 0 ===
; Triggers when the sensor detects a hole in the wheel.
; Four holes on the wheel.
; To reach 80RPS, there will be 320 rotations per second so
; we need to store this value in a word.

EXT_INT0:
	push ZL
	push ZH
	push temp
	in temp, SREG
	push temp

	ldi ZL, low(var_numinterrupts)
	ldi ZH, high(var_numinterrupts)

	ld temp, Z

	subi temp, -1
	;mov num_interrupts, r3
	st Z, temp

	pop temp
	out SREG, temp
	pop temp
	pop ZH
	pop ZL
reti


; === TIMER OVERFLOW 0 ===
Timer0:                  ; Prologue starts.
push temp                 ; Save all conflict registers in the prologue.
in temp, SREG
push temp                 
push temp2 
; Prologue ends.

/**** a counter for 3597 is needed to get one second-- Three counters are used in this example **************/                                          
                         ; 3597  (1 interrupt 278microseconds therefore 3597 interrupts needed for 1 sec)

; HOWEVER: to avoid complication of dividing by 4, we can interrupt every 1/4 of a second. 899.25 interrupts per 1/4 second
cpi counter, 99          ; counting for 99
brne notsecond
 
cpi counter2, 8         ; counting for 8
brne secondloop          ; jumping into count 100 

outmot: ldi counter,0    ; clearing the counter values after counting 3597 interrupts which gives us one second
        ldi counter2,0
        ldi counter3,0
        
		; So in one second, we have detected var_numinterrupts
		; Dividing num_interrupts by 4 we get how many revolutions persecond.
		; This is equal to number of interrupts per quarter second.
		
		; Set var_realrpm to var_numinterrupts/4, and reset var_numinterrupts

		ldi ZL, low(var_numinterrupts) ; load numinterrupts to temp
		ldi ZH, high(var_numinterrupts)

		ld temp, Z

		; adjust realrpm
		ldi ZL, low(var_motrpm) ; load user set RPS to temp2
		ldi ZH, high(var_motrpm)

		ld temp2, Z
		; compare realrpm and motrpm - and try to fix the result
		; by widening or shortening the pulses as appropriate
		ldi ZL, low(var_adjustedrpm)
		ldi ZH, high(var_adjustedrpm)
		cp temp, temp2 
		brlo tooslow ; if temp <= temp2, too slow!
		toofast:
			ld temp2, Z

			cpi temp2, 2 ; if temp2 < 2, dont deduct (underflow)
			brlo else
			subi temp2, 1 ; take 1 from user RPS
			rjmp else
		tooslow:
			ld temp2, Z
			subi temp2, -1 ; add 1 to user RPS
			cpi temp2, 85 ; make sure it doesn't get too fast (max 85)
			brlo else
			ldi temp2, 85
		else:
		st Z, temp2	
	

		ldi ZL, low(var_realrpm)
		ldi ZH, high(var_realrpm)

		st Z, temp


		ldi ZL, low(var_numinterrupts) ; numinterrupts = 0
		ldi ZH, high(var_numinterrupts)

		ldi temp, 0
		st Z, temp

		

        rjmp exit        ; go to exit

notsecond: inc counter   ; if it is not a second, increment the counter
           rjmp exit

secondloop: inc counter3 ; counting 100 for every 35 times := 35*100 := 3500
            cpi counter3,100 
            brne exit
	    inc counter2
	    ldi counter3,0                  
exit: 
pop temp2
pop temp                  ; Epilogue starts;
out SREG, temp            ; Restore all conflict registers from the stack.
pop temp
reti                     ; Return from the interrupt.                 ; Return from the interrupt.


; == Takes in (in 'temp'), an unsigned 8 bit number and prints it.

print_unsigned:
	push temp  ; holds the current most significant digit
	push temp2 ; holds a copy of the original value
	push mask  ; holds the original value

	mov temp2, temp ; temp2 = value
	mov mask, temp ; mask = value
	; == Get 100s ==
	
	cpi mask, 100 ; if value < 100, skip
	brlo skip_hundreds

	clr data ;data = 0
	ldi temp, 100 ; MSD temp = 100

	hundreds_loop:

	cp temp2, temp ; while temp2 >= 100
	brlo exit_hundreds

	sub temp2, temp ;temp2 -= temp
	inc data
	rjmp hundreds_loop
	exit_hundreds:


	subi data, (-'0')
    rcall lcd_wait_busy
	rcall lcd_write_data            ; write the character to the screen

	skip_hundreds:

	; == Get 10s ==
	cpi mask, 10 ; if data < 10, skip
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
	rcall lcd_write_data            ; write the character to the screen

	skip_dozens:
	; == Get 1s ==
	ldi temp, 1 ; get 10s
	clr data ; data = 0
	ones_loop:
	cp temp2, temp ; while temp2 >= 1
	brlo exit_ones

	sub temp2, temp
	inc data

	rjmp ones_loop
	exit_ones:

	subi data, (-'0')
    rcall lcd_wait_busy
	rcall lcd_write_data            ; write the character to the screen


	pop mask
	pop temp2
  	pop temp

ret




;Function lcd_write_com: Write a command to the LCD. The data reg stores the value to be written.
lcd_write_com:
	push temp
	in temp, SREG
	push temp
	push temp2

	; temp = low part of data (to PORTB)
	; temp2 = high part of data (to PORTD)

	mov temp, data
	andi temp, 0b00001111

	mov temp2, data
	andi temp2, 0b11110000


	out PORTB, temp ; set the data port's value up (low part of data)
	out PORTD, temp2

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

	pop temp2
	pop temp
	out SREG, temp
	pop temp
	ret

;Function lcd_write_data: Write a character to the LCD. The data reg stores the value to be written.
lcd_write_data:
	push temp
	in temp, SREG
	push temp
	push temp2

	; temp = low part of data (to PORTB)
	; temp2 = high part of data (to PORTD)

	mov temp, data
	andi temp, 0b00001111

	mov temp2, data
	andi temp2, 0b11110000


	out PORTB, temp ; set the data port's value up (low part of data)
	out PORTD, temp2

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


	pop temp2
	pop temp
	out SREG, temp
	pop temp
ret

;Function lcd_wait_busy: Read the LCD busy flag until it reads as not busy.
lcd_wait_busy:
	push temp
	in temp, SREG
	push temp

	clr temp
	out DDRB, temp ; Make PORTB be an input port for now
	out PORTB, temp
	
	out DDRD, temp 	; PORTD too
	out PORTD, temp

	ldi temp, 1 << LCD_RW
	out PORTA, temp ; RS = 0, RW = 1 for a command port read
	busy_loop:
	nop ; delay to meet timing (Set up time / Enable cycle time)
	sbi PORTA, LCD_E ; turn on the enable pin
	nop ; delay to meet timing (Data delay time)
	nop
	nop
	in temp, PIND ; read value from LCD 
	; LCD_BF is on bit 7, so read port D not port B

	cbi PORTA, LCD_E ; turn off the enable pin
	sbrc temp, LCD_BF ; if the busy flag is set

	rjmp busy_loop ; repeat command read
	clr temp ; else
	out PORTA, temp ; turn off read mode,
	ser temp
	out DDRB, temp ; make PORTB an output port again

	; make only high parts of PORTD input (needed to combine high PORTD and leave low PORTD for ext interrupts)
	ldi temp, 0b11110000
	out DDRD, temp ; make PORTD output again too

	pop temp
	out SREG, temp
	pop temp
ret ; and return


; Function delay: Pass a number in registers r18:r19 to indicate how many microseconds
; must be delayed. Actual delay will be slightly greater (~1.08us*r18:r19).
; r18:r19 are altered in this function.

;delay for del_hi:del_lo us
delay:
	push temp_low
	push temp_high
	push temp
	in temp, SREG
	push temp
	; frequency = 7.328mhz
	; = 7,328,000 instructions per second
	; = 7,328 instructions per millisecond
	; = 7.328 instructions per microsecond
	clr temp_high
	clr temp_low
	delay_loop_outer: ;occurs once for each del_hi:del_lo
	;increment loop
	adiw temp_low, 1 ; 2
	nop ; 2 nops
	nop

	cp temp_low, del_lo ; 1 Cycle
	cpc temp_high, del_hi ; 1 Cycle
	brlt delay_loop_outer ;2 Cycles

	; 8 cycles per loop, greater than the required 7.328
	pop temp
	out SREG, temp
	pop temp
	pop temp_high
	pop temp_low
ret


;Function lcd_init Initialisation function for LCD.
lcd_init:
	push temp
	in temp, SREG
	push temp

	ser temp
	out DDRB, temp ; PORTB, the data port is usually all otuputs
	out DDRA, temp ; PORTA, the control port is always all outputs
	ldi temp, (1<<PD4)|(1<<PD5)|(1<<PD6)|(1<<PD7) ; set top half of PORTD as outputs (for LCD)
	out DDRD, temp

	ldi del_lo, low(15000)
	ldi del_hi, high(15000)
	rcall delay ; delay for > 15ms
	; Function set command with N = 1 and F = 0
	ldi data, LCD_FUNC_SET | (1 << LCD_N)
	rcall lcd_write_com ; 1st Function set command with 2 lines and 5*7 font
	ldi del_lo, low(4100)
	ldi del_hi, high(4100)
	rcall delay ; delay for > 4.1ms
	rcall lcd_write_com ; 2nd Function set command with 2 lines and 5*7 font
	ldi del_lo, low(100)
	ldi del_hi, high(100)
	rcall delay ; delay for > 100us
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

	pop temp
	out SREG, temp
	pop temp
ret

