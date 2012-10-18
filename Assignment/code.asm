// Cabling:
// KEYPAD      -> PD0-PD7
// LCD         -> PC0-PC7
// LCD CONTROL -> PA0-PA4
// PB1         -> doubled up on PD0
// Motor       -> PB4

// Assignment Version X
// - Additional features/changes here

// Assignment Version 0.1
// - Only does basic LED proof-of-concept
.include "m64def.inc"

// Assignment Version 0.2a - Stanley
// - Added functional LCD
// - Working on printing query string

// Assignment Version 0.3 - Stanley
// - General keypad functionality working
// - Merged.

// TODO:
// DONE - both number and letter mode should allow # for finish entering data (e.g. enter your name, [name]#)
// DONE - letter mode should allow for * to confirm the character, (e.g. 222* = C)
// - a way to access all the alphabetical letters
//    + perhaps a wrapper over scan_for_key, that interprets data properly.
// - 
.def temp = r16
.
.def temp2 = r26
.def orig = r17 // dupe used for writeNumber
.def row = r17 // dupe used for row for keypad polling
.def col = r18 // keypad polling related
.def del_lo = r19
.def arrayIndex = r19
.def stationNumber = r19
// .def count = r27 // dupe used for polling keypad
.def del_hi = r20
.def arrayData = r20
.def counter = r21
.def counter2 = r22
.def counter3 = r23
.def data = r24 // Used in LCD Functions
.def mask = r25 // Keypad polling related
;.def var = r26 x // used above
;.def var = r27 x // used above
;.def var = r28 y
;.def var = r29 y
;.def var = r30 z
.def keypadMode = r31

.dseg
   .org 0x690
   wrapperStorage: .byte 1

   .org 0x700
   wrapperPreviousChar: .byte 1

   .org 0x100
array: .byte 200 ; 100 x 1 byte numbers

.cseg

jmp RESET
jmp Default ; IRQ0 Handler
jmp Default ; IRQ1 Handler
jmp Default ; IRQ2 Handler
jmp Default ; IRQ3 Handler
jmp Default ; IRQ4 Handler
jmp Default ; IRQ5 Handler
jmp EXT_INT6 ; IRQ6 Handler
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

.equ LCD_CURSOR_GO_BACK_1 = 0b00010000 // 00 means, send cursor back 1. (after the 1) 
.equ LCD_CURSOR_GO_FORW_1 = 0b00010100 // 
// keypadRead modes
.equ LETTER_MODE = 1
.equ NUMBER_MODE = 2


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

// KEYPAD bits and constants
.equ PORTDDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F


Default:
reti

RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp

// Set read number flag to true because first thing to be
// asked is "Please type the maximum number of stations:"
ldi keypadMode, NUMBER_MODE;

//Initialise the LCD
rcall lcd_init

// Clear the display
ldi data, LCD_DISP_CLR
rcall lcd_write_com ; Clear Display
rcall lcd_wait_busy ; Wait until the LCD is ready

//falling edge for EXT_INT0
ldi temp, (2<<ISC60)
out EICRB, temp

//enable EXT_INT4
ldi temp, (1<<INT6)
out EIMSK, temp

//motor out + led out
ldi temp, (1<<DDB4)|(1<<DDB0)
out DDRB, temp

clr temp
out PORTB, temp

//set motor
ldi temp, 100 
out OCR0, temp

//Timer enable (normally enabled on EXT_INT0
//ldi temp, (1<<TOIE0) ; =278 microseconds
//out TIMSK, temp ; T/C0 interrupt enable

ldi temp, (1<<WGM01) | (1<<WGM00) | (2<<COM00) | (2<<CS00)
/*	WGM01 + WGM00 = NO force output compare (for PWN modes)
COM00 = Clear OC0 on Compare Match when up-counting. Set OC0 on Compare Match when downcounting.
CS00 = Prescaler = 8
*/
out TCCR0, temp

// KEYPAD
ldi temp, PORTDDIR ; columns are outputs, rows are inputs
out DDRD, temp

sei

// String definitions for query strings
number_of_stations_query: .db "max stat: "
name_station_query: .db "name stat "


main:

	rcall lcd_wait_busy
	ldi data, 10
	rcall lcd_write_name_station_in_data
	// WRITE THE FIRST LINE

	ldi data, LCD_GO_TO_START_2ND_LINE
	rcall lcd_wait_busy
	rcall lcd_write_com
	// CHANGE THE POINTER TO THE SECOND LINE
   
   inputLoop:
   cpi data, '#'
   breq end
	rcall letter_input_wrapper
   jmp inputLoop	




end: 

rjmp end

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

EXT_INT6:
	push temp
	in temp, SREG
	push temp
	push temp2

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
		ldi temp, 0
		out OCR0, temp

		jmp exitInt

	disableTimer:

		ldi temp, (0<<TOIE0) ; =278 microseconds
		out TIMSK, temp ; T/C0 interrupt disable

		//set motor
		ldi temp, 100
		out OCR0, temp

		in temp, DDRB
		push temp

		ldi temp, (1<<DDB0)
		out DDRB, temp

		clr temp
		out PORTB, temp

		pop temp
		out DDRB, temp

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


		in temp, DDRB
		push temp

		ldi temp, (1<<DDB0)
		out DDRB, temp

		ser temp2
		in temp, PINB
		eor temp, temp2
		out PORTB, temp
                
		pop temp
		out DDRB, temp

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
	push temp
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
	pop temp
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

/********************************************************************/
/********** KEYPAD CODE BELOW THIS POINT ****************************/
/********************************************************************/

scan_for_key:
ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop:
out PORTD, mask ; set column to mask value
; (sets column 0 off)
ldi temp, 0xFF ; implement a delay so the
; hardware can stabilize
delay:
dec temp
brne delay
in temp, PIND ; read PORTD
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

cpi data, '.'
breq scan_for_key

ret ; and start again

skipconv:
inc row ; else move to the next row
lsl mask ; shift the mask to the next bit
jmp rowloop
nextcol:
cpi col, 3 ; check if we’re on the last column
breq scan_for_key ; if so, no buttons were pushed,
; so start again.
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

skipclear:

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
; row*3 + col + 1
push temp2
ldi temp2, '0'
add temp, temp2
pop temp2

jmp convert_end
letters:
	ldi temp, 'A'
	add temp, row ; increment from 0xA by the row value
	jmp convert_end

symbols:
cpi col, 0 ; star
breq star

cpi col, 1 ; zero
breq zero

ldi temp, '#' ; astrisk only left
jmp convert_end

star:
ldi temp, '*'
jmp convert_end

zero:
ldi temp, '0'
jmp convert_end

convert_end:

mov data, temp

dontprint:
ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop2:
out PORTD, mask ; set column to mask value
; (sets column 0 off)
ldi temp, 0xFF ; implement a delay so the
; hardware can stabilize
delay2:
dec temp
brne delay2
in temp, PIND ; read PORTD
andi temp, ROWMASK ; read only the row bits
cpi temp, 0xF ; check if any rows are grounded
breq nextcol2 ; if not go to the next column
ldi mask, INITROWMASK ; initialise row check
clr row ; initial row
rowloop2:
mov temp2, temp
and temp2, mask ; check masked bit
brne dontprint ; if the result is non-zero,

inc row ; else move to the next row
lsl mask ; shift the mask to the next bit
jmp rowloop2
nextcol2:
cpi col, 3 ; check if we’re on the last column
breq return ; if so, no buttons were pushed,
; so start again.
sec ; else shift the column mask:
; We must set the carry bit
rol mask ; and then rotate left by a bit,
; shifting the carry into
; bit zero. We need this to make
; sure all the rows have
; pull-up resistors
inc col ; increment column value
jmp colloop2 ; and check the next column
; convert function converts the row and column given to a
; binary number and also outputs the value to PORTC.
; Inputs come from registers row and col and output is in
; temp.

return:

ret ; return to caller

// This function wraps "scan_for_key" and implements SMS-like
// text input functionality - motherfucker.
letter_input_wrapper:
   push ZH
   push ZL
   push temp
   in temp, SREG
   push temp
   push temp2

   ldi ZH, high(wrapperStorage)
   ldi ZL, low(wrapperStorage)
   ldi data, '!'
   st Z, data // store an initial character

   ldi temp2, 0 // Temp2 indicates if we've already printed something, 
   // e.g. we're cycling through something.

   // temp is used to store what we read in the last turn 
   // through memory access
   
   ldi keypadMode, LETTER_MODE // ensure letter mode

   processLoop:
      ldi ZH, high(wrapperPreviousChar)
      ldi ZL, low(wrapperPreviousChar)
      st Z, temp2

      rcall scan_for_key // get an input
      
      ldi ZH, high(wrapperPreviousChar)
      ldi ZL, low(wrapperPreviousChar)
      ld temp2, Z
      
      cpi data, '#' // If someone pressed a hash, pass it straight through
      breq quitLetterInputMidJump

      // So we're reading something now, grab what it was.
      ldi ZH, high(wrapperStorage)
      ldi ZL, low(wrapperStorage)
      ld temp, Z // grab what we previously read

      // compare it to what we've gotten
      cp temp, data
      breq pressedAgain // if they're equal - we pressed again.
      // else user pressed a new thing.
      ldi temp2, 0
      st Z, data // remember what it was we were reading

      pressedAgain:
         inc temp2
         // manual modulo it, to find out which letter we want
         // To modulo:
         // if > 3, subtract 3
         // that's it.
         cpi temp2, 4
         brne dontSubtract
         ldi temp2, 1 // I know it's 4, so 4-3 = 1
         dontSubtract:

         cpi data, '2' // here's my huge IF statement
         brne not2
         ldi data, 'A'
         add data, temp2 // temp2 stores how many times u've pressed it
         dec data // subtract, because 1 instance of '1' is A not B.
         not2:

         cpi data, '3' 
         brne not3
         ldi data, 'D'
         add data, temp2
         dec data         
         not3:

         cpi data, '4'
         brne not4
         ldi data, 'G'
         add data, temp2
         dec data
         not4:

         cpi data, '5'
         brne not5
         ldi data, 'J'
         add data, temp2
         dec data
         not5:

         // Workaround for 
         jmp protected
         quitLetterInputMidJump:
         jmp quitLetterInput
         protected:

         cpi data, '6'
         brne not6
         ldi data, 'M'
         add data, temp2
         dec data
         not6:

         cpi data, '7'
         brne not7
         ldi data, 'P'
         add data, temp2
         dec data
         not7:

         cpi data, '8'
         brne not8
         ldi data, 'T'
         add data, temp2
         dec data
         not8:

         cpi data, '9'
         brne not9
         ldi data, 'W'
         add data, temp2
         dec data
         not9:

         cpi data, '0'
         brne not0
         ldi data, 'Z'
         not0:

         cpi data, '*'
         brne notAstrisk
         ldi data, '*'
         push data
         ldi data, LCD_CURSOR_GO_FORW_1
         rcall lcd_wait_busy ; Wait until the LCD is ready
         rcall lcd_write_com
         pop data
         // also move the LCD pointer forward, and set it back to normal mode
         jmp quitLetterInput // and finish.
         notAstrisk:

                  // TODO Send command to write but not increment pointer


         // The above don't need escapes because they are all guarded.
         // Draw this character to the LCD, but don't increment the pointer
         push temp2
         rcall lcd_wait_busy
         rcall lcd_write_data// so write over whatever we have.
         pop temp2

         push data
         ldi data, LCD_CURSOR_GO_BACK_1
         rcall lcd_wait_busy ; Wait until the LCD is ready
         rcall lcd_write_com
         pop data
      jmp processLoop

   quitLetterInput:

   pop temp2
   pop temp
   out SREG, temp
   pop temp
   pop ZL
   pop ZH


ret


/********************************************************************/
/********** KEYPAD CODE ABOVE THIS POINT ****************************/
/********************************************************************/

/********************************************************************/
/********** ARRAY MANIPULATION CODE *********************************/
/********************************************************************/
writeDataToArray:
	push temp
	push r26
	push r27

	ldi r26, low(array) ; grab a handle to the array
	ldi r27, high(array)

	ldi temp, 0
	; Go forward "parameter" indexes
	find_parameter_index :
		cp temp, arrayIndex
		breq find_parameter_index_skip
		adiw r26, 1 ; increment the poiner
		inc temp
		jmp find_parameter_index

	find_parameter_index_skip :

		st X, arrayData

		pop r27
		pop r26
		pop temp
ret

readDataArray:
	push temp
	push r26
	push r27

	ldi r26, low(array) ; grab a handle to the array
	ldi r27, high(array)

	ldi temp, 0
	; Go forward "parameter" indexes
	find_parameter_index2 :
		cp temp, arrayIndex
		breq find_parameter_index_skip2
		adiw r26, 1 ; increment the poiner
		inc temp
		jmp find_parameter_index2

	find_parameter_index_skip2 :

		ld arrayData, X

		pop r27
		pop r26
		pop temp
ret

setPointerToStation:
	push temp
	mov temp, stationNumber
	push temp

	ldi r26, low(array) ; grab a handle to the array
	ldi r27, high(array)

	check_station_number:
	cpi stationNumber, 1
	breq skip_ten_loop

		ldi temp, 0
		; Go forward "parameter" indexes
		find_parameter_index3 :
			cpi temp, 10
			breq find_parameter_index_skip3
			adiw r26, 1 ; increment the poiner
			inc temp
			jmp find_parameter_index3

		find_parameter_index_skip3 :

			subi stationNumber, 1
			jmp check_station_number
	skip_ten_loop:

		pop temp
		mov temp, stationNumber
		pop temp

ret
