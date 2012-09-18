/****  ExampleW.3.1    ******************************************/
         ; This example demonstrates on how the switching can be 
        ; implemented using the external interrupt.        
         ; The Motor is switched on and off using switches PB0 PB1
		 ;*******************************************************
		 ; connections:
		 ;       PB0 (input pin) -> PD0 (External Interrupt 0)
		 ;       PB1 (input pin) -> PD1 (External Interrupt 1)
		 ;       Mot             -> PC0
		 ; External interrupts ::refer ATMega64DataSheet page 89
		 ;NOTE: External interrupts occur based on SREG...i flag
		 ;
		 ;**********************
         ;
		 ;      
		 ; 
/****************************************************************/
.include "m64def.inc"
.def temp =r16

; Setup the interrupt vectors so that the task will be given
; to the necessary subroutine when there is an interrupt

jmp RESET
.org INT0addr ; INT0addr is the address of EXT_INT0
jmp EXT_INT0
.org INT1addr ; INT1addr is the address of EXT_INT1
jmp EXT_INT1

; interrupt place when Reset button is pressed
RESET:

ldi temp, 0b01101010
out TCCR0, temp

ldi temp, 0xA4
out OCR0, temp

ldi temp, low(RAMEND)      ;initializing stack pointers
out SPL, temp
ldi temp, high(RAMEND)
out SPH, temp
ser temp                   ; set the temp register
out DDRC,temp              ; making PORTC as output
ldi temp, (2 << ISC10) | (2 << ISC00) ;setting the interrupts for falling edge
sts EICRA, temp                       ;storing them into EICRA 
in temp, EIMSK                        ;taking the values inside the EIMSK  
ori temp, (1<<INT0) | (1<<INT1)       ; oring the values with INT0 and INT1  
out EIMSK, temp                       ; enabling interrput0 and interrupt1
sei                        ; enabling the global interrupt..(MUST)
jmp main


; interrupt place invoked by EXT interrupt0 when button PB0 is pressed
EXT_INT0:                  ; saving the temp value into the stack  
push temp
in temp, SREG              ; inserting the SREG values into temp
push temp                  ; saving the temp into stack
ldi temp,0                 ; storing 0s into temp
out PORTC, temp            ; sending 0s out to PORTC 
pop temp                   ; taking out temp from stack which has SREG
out SREG, temp             ; copy the values in temp into SREG
pop temp                   ; take the temp value from stack
reti



; interrupt place invoked by EXT interrupt1 when button PB1 is pressed
EXT_INT1:
push temp
in temp, SREG
push temp


//ldi temp,1
//out PORTC,temp // outputs run to the motor
; AT INITIALISATION, RUN MOTOR AT 20% EFFICIENCY
ldi temp, 0
out FOC0, temp
ldi temp, 1

// WGM01: 0, WGM00: 1 = PHASE CORRECT PWM mode
out WGM01, temp
ldi temp, 1
out WGM00, temp

// COM01: 1, COM00: 1 = Set OC0 on Compare Match when up-counting. Clear OC0 on Compare 
// Match when downcounting.
out COM01, temp
out COM00, temp

// OCR0 determines duty... so lets try a random number
ldi temp, 255
out OCR0, temp


pop temp
out SREG, temp
pop temp
reti


; Main does not do anything in here  !!
main:
clr temp

loop:
rjmp loop
