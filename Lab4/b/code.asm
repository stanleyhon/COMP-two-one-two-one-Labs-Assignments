// CAREFUL WHAT MODE THE COUNTER IS IN
// ADDED DELAY INSIDE INTERRUPT SO THAT IT DOESN'T INTERRUPT WHILE IN HOLE
// DELAY WAS 2300

// BASE YOUR LCD WRITE FUNCT ON RANDAL'S

// PUT THE ACTUAL COUNT IN THE RIGHT PLACE BECAUSE IF U PUT IN MAIN, ONLY WILL WORK WHEN PRESS KEY

/*
  Keypad => PC0-PC7
	LCD(Debug) => PD0-PD7
	LCD Control(Debug) => PA0-PA3
	Mot => PB4

	PB0 => OpE
	PE4 => OpD

	ï INT4/OC3B ñ Port E, Bit 4
	INT4, External Interrupt Source 4: The PE4 pin can serve as an External Interrupt source.
	OC3B, Output Compare Match B output: The PE4 pin can serve as an external output for the
	Timer/Counter3 Output Compare B. The pin has to be configured as an output (DDE4 set ñ one)
	to serve this function. The OC3B pin is also the output pin for the PWM mode timer function.
*/

.include "m64def.inc"
.def temp =r16
.def row =r17
.def col =r18
.def mask =r19
.def count = r20

// ************* LCD COPY ********************

.def data =r21
.def del_lo = r22
.def del_hi = r23

.def temp2 = r24
.def timerOverflow = r25

// *********** ABOVE LCD COPY *******************
.equ PORTDDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

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

.dseg

holeCount: .byte 1 ; keeps track of hole count

.cseg

jmp RESET         ; Reset Handler
jmp noInt    ; IRQ0 Handler
jmp noInt    ; IRQ1 Handler
jmp noInt    ; IRQ2 Handler
jmp noInt    ; IRQ3 Handler
jmp EXT_INT4    ; IRQ4 Handler
jmp noInt ; irq5
jmp noInt ; 6
jmp noInt ; 7
jmp noInt ; timer2
jmp noInt
jmp noInt ; timer 1
jmp noInt
jmp noInt ; timer 0 compare
jmp Timer0 ; timer 0 overflow

noInt:
   reti



RESET:
ldi temp, low(RAMEND)
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ldi temp, PORTDDIR ; columns are outputs, rows are inputs
out DDRC, temp


; INTERRUPTS FOR COUNTING SPINS

// MASTER OF ASSEMBLY (r)


//3 = CONSTANT INTERRUPTS
//2 = 
//1 = 


; enabling interrupt
ldi temp, (1 << ISC40) 				;setting the interrupts for falling edge
sts EICRB, temp                       ;storing them into EICRB	
in temp, EIMSK                        ;taking the values inside the EIMSK  
ori temp, (1<<INT4)      			
out EIMSK, temp                       ; enabling interrupt4
//ldi temp, 1
//out DDE4, temp //Set PORTE to out

rcall lcd_init
ldi count, 0
dec count

ldi temp, (1<<WGM01) | (1<<WGM00) | (2<<COM00) | (2<<CS00)
/*	WGM01 + WGM00 = NO force output compare (for PWN modes)
COM00 = Clear OC0 on Compare Match when up-counting. Set OC0 on Compare Match when downcounting.
CS00 = Prescaler = 8
*/
out TCCR0, temp

ldi temp, 70
out OCR0, temp

ser temp
out DDRB, temp

sei

; main keeps scanning the keypad to find which key is pressed.
main:

ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop:
//rcall RPS
out PORTC, mask ; set column to mask value
; (sets column 0 off)
ldi temp, 0xFF ; implement a delay so the
; hardware can stabilize
delay:

dec temp
brne delay
in temp, PINC ; read PORTD
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


jmp main ; and start again

skipconv:
inc row ; else move to the next row
lsl mask ; shift the mask to the next bit
jmp rowloop
nextcol:
cpi col, 3 ; check if weíre on the last column
breq main ; if so, no buttons were pushed,
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

inc count
cpi count, 16
brmi skipclear

rcall lcd_init

ldi count, 0


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
convert_end:
//out PORTC, temp ; write value to PORTC

cpi temp, 1
breq gofaster
cpi temp, 2
breq goslower
cpi temp, 3
breq stopMotor
cpi temp, 4
breq startMotor
jmp dont
gofaster: 
	push temp
	in temp, SREG
	push temp

	in temp, OCR0

	subi temp, -8
	cpi temp, 246
	brlo outnow
	ldi temp, 246

	outnow:
	out OCR0, temp

	pop temp
	out SREG, temp
	pop temp
	jmp dont

goslower:
	push temp
	in temp, SREG
	push temp


	in temp, OCR0
	cpi temp, 68
	brlo tooSmall 
	subi temp, 8
	out OCR0, temp

	tooSmall:
	pop temp
	out SREG, temp
	pop temp
	jmp dont

stopMotor:
	push temp
	in temp, SREG
	push temp


	ldi temp, 0
	out OCR0, temp

	pop temp
	out SREG, temp
	pop temp
	jmp dont
startMotor:
	push temp
	in temp, SREG
	push temp

	ldi temp, 60
	out OCR0, temp

	pop temp
	out SREG, temp
	pop temp
	jmp dont	

dont:

dontprint:
ldi mask, INITCOLMASK ; initial column mask
clr col ; initial column
colloop2:
out PORTC, mask ; set column to mask value
; (sets column 0 off)
ldi temp, 0xFF ; implement a delay so the
; hardware can stabilize
delay2:
dec temp
brne delay2
in temp, PINC ; read PORTD
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
cpi col, 3 ; check if weíre on the last column
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



// ******************************* BELOW THIS LINE LCD COPY  STUFF *********** //

//Function lcd_write_com: Write a command to the LCD. The data reg stores the value to be written.
lcd_write_com:
out PORTD, data ; set the data port's value up
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
out PORTD, data ; set the data port's value up
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
out DDRD, temp ; Make PORTD be an input port for now
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
cbi PORTA, LCD_E ; turn off the enable pin\]
sbrc temp, LCD_BF ; if the busy flag is set
rjmp busy_loop ; repeat command read
clr temp ; else
out PORTA, temp ; turn off read mode,
ser temp
out DDRD, temp ; make PORTD an output port again
ret ; and return
; Function delay: Pass a number in registers r18:r19 to indicate how many microseconds
; must be delayed. Actual delay will be slightly greater (~1.08us*r18:r19).
; r18:r19 are altered in this function.
; Code is omitted
;Function lcd_init Initialisation function for LCD.
lcd_init:
ser temp
out DDRD, temp ; PORTD, the data port is usually all otuputs
out DDRA, temp ; PORTA, the control port is always all outputs
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


bigdelay:
  push del_lo
  push del_hi

  ldi temp2, 38
  delayloop :
  ldi del_lo, low(50000)
  ldi del_hi, high(50000)
  rcall delayCTL
  subi temp2, 1
  brne delayloop
 
  pop del_hi
  pop del_lo
ret

smalldelay:
  push del_lo
  push del_hi

  ldi temp2, 2
  delayloop2 :
  ldi del_lo, low(50000)
  ldi del_hi, high(50000)
  rcall delayCTL
  subi temp2, 1
  brne delayloop2
 
  pop del_hi
  pop del_lo
ret

interruptDelay:
   push del_lo
   push del_hi

   ldi temp2, 1
   delayloop3:
      ldi del_lo, low(2300)
      ldi del_hi, high(2300)
      rcall delayCTL
      subi temp2, 1
      brne delayloop3

   pop del_hi
   pop del_lo
ret

// interrupt handler
EXT_INT4:
	push ZL
   push ZH
   push temp
   in temp, SREG
   push temp

   // INCREMENT THE COUNT WHEREVER IT IS
   ldi ZL, low(holeCount)
   ldi ZH, high(holeCount)

   ld temp, Z

   inc temp
   rcall print_unsigned

st Z, temp

   ldi temp, ' '
   rcall print_unsigned


    //WAIT 2300
   rcall interruptDelay 

   pop temp
   out SREG, temp
   pop temp
   pop ZH
   pop ZL
reti

// interrupt handler
RPS:
	push ZL
   push ZH
   push temp
   in temp, SREG
   push temp
	push data


   // INCREMENT THE COUNT WHEREVER IT IS
	ldi ZL, low(holeCount)
   ldi ZH, high(holeCount)

	ldi temp, 0
	st Z, temp

	rcall smalldelay


	ldi data, LCD_DISP_CLR
	rcall lcd_wait_busy
	rcall lcd_write_com 
	
	
   	ld temp, Z
	rcall print_unsigned


   st Z, temp
	
   // WAIT 2300
   //rcall interruptDelay 

  pop data
   pop temp
   out SREG, temp
   pop temp
   pop ZH
   pop ZL
ret

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


Timer0:

/*
   push temp
   in temp, SREG
   push temp

   // EACH TIME TIMER OVERFLOWED SHOULD BE 1/2 second ish
   // SO OVERFLOW TWICE
   cpi timerOverflow, 2
   breq isSecond

   isSecond:
      // clear timerOverflow
      ldi timerOverflow, 0
      push ZL
      push ZH
      ldi ZL, low(holeCount)
      ldi ZH, high(holeCount)

      ld temp, Z


   pop temp
   out SREG, temp
   pop temp
*/

reti
