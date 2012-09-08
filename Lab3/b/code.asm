; It is assumed that the following connections on the board are made:
; LCD D0-D7 -> PD0-PD7
; LCD BE-RS -> PA0-PA3
; These ports can be changed if required by replacing all references to the ports with a
; different port. This means replacing occurences of DDRx, PORTx and PINx.

.include "m64def.inc"
.def temp =r16
.def data =r17
.def del_lo = r18
.def del_hi = r19

.def min_lo = r20
.def min_hi = r21
.def sec_lo = r22
.def sec_hi = r23


.def temp2 = r24
. 
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

;


;*****************************************************************************************
; Everything below here can be replaced.  This is some sample code to show it all working.
;*****************************************************************************************
     
      string: .db "Hello World!"
     .equ LENGTH = 5
     .def count = r24
         
; Function main: Test the LCD by writing some characters to the screen.  Desired output is:
; Hello World! 
; 123456789012 
main: 
  	ldi temp, low(RAMEND)
        out SPL, temp
        ldi temp, high(RAMEND)
        out SPH, temp

        rcall lcd_init

		ldi min_hi, '0'
		ldi min_lo, '0'
		ldi sec_hi, '0'
		ldi sec_lo, '0'

main_loop:
        rcall bigdelay //delay 1 sec
		inc sec_lo
		cpi sec_lo, '9'+1
		brlo skip

		ldi sec_lo, '0'
		inc sec_hi
		cpi sec_hi, '5'+1
		brlo skip

		ldi sec_hi, '0'
		inc min_lo
		cpi min_lo, '9'+1
		brlo skip

		ldi min_lo, '0'
		inc min_hi
		cpi min_hi, '9'+1
		brlo skip

		ldi min_hi, '0'
		ldi min_lo, '0'
		ldi sec_hi, '0'
		ldi sec_lo, '0'

skip:

		mov data, min_hi
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 

		mov data, min_lo
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 

		ldi data, ':'
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 

		mov data, sec_hi
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 

		mov data, sec_lo
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 

		rcall lcd_wait_busy
        ldi data, LCD_ADDR_SET | LCD_LINE1
        rcall lcd_write_com
        jmp main_loop

end: 
        rjmp end                                        ; infinite loop


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
ret





//4000000 cycles/sec
//4000 cycles/ms - 4 cycles/micro sec

delay: //3 cycles
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

  ldi temp2, 40
  delayloop :
  ldi del_lo, low(50000)
  ldi del_hi, high(50000)
  rcall delay
  subi temp2, 1
  brne delayloop
 
  pop del_hi
  pop del_lo
ret
