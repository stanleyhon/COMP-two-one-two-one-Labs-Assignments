.include "m64def.inc"

.def parameter1 = r16
.def parameter2 = r17
.def counter = r18
.def temp = r18
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

; Define the data segment for the array
.dseg
.org 0x100
testArray: .byte 20 ; 10x 2 byte numbers
.cseg

ldi r26, low(testArray)
ldi r27, high(testArray)

; This macro writes array values to SRAM
.macro writeToArray
	ldi r16, low(@0)
	ldi r17, high(@0)
	st X+, r16
	st X+, r17
	clr r16
	clr r17
.endmacro


; Fill the array
; int test[10] = {100, 209, -725, -200, 500, 301, 60, -400,100, 80};
writeToArray 100
writeToArray 209
writeToArray -725
writeToArray -200
writeToArray 500
writeToArray 301
writeToArray 60
writeToArray -400
writeToArray 100
writeToArray 80

main:
   ldi r28, low(RAMEND-4)
   ldi r29, high(RAMEND-4)
   out SPH, r29
   out SPL, r28
   clr r0


loop: nop
   jmp loop

; This function swaps the two array indexes
; Frame Contents:
; Y+1,Y+2 - array[parameter1]
; Y+3,Y+3 - array[parameter2]
; Frame size:
; 2 bytes to save X
; 2 bytes to save Y
; 2 bytes to save Z
swapArrayIndexes:
   push r28 ; Save SPL (Y low)
   push r29 ; Save SPH (Y high)
   push r26 ; Save X low
   push r27 ; Save X high
   push r30 ; Save Y low
   push r31 ; Save Y high
   in r28, SPL ; Grab the new stack low address
   in r29, SPH ; Grab the new stack high address
   sbiw r28, 10 

   out SPH, r29
   out SPL, r28

   ; grab the location of the low point of the array
   ldi r26, low(testArray)
   ldi r27, high(testArray)
   ldi r30, low(testArray)
   ldi r31, high(testArray)

   ldi counter, 0
   ; Go forward "parameter1" indexes
   find_parameter1_index :
   cp counter, parameter1 ; pre-condition guard
   brlt find_parameter1_index_skip
      adiw r26, 1 ; increment the poiner
	  adiw r30, 1 ; Also increment Z pointer so we can find this again later.
	  inc counter
	  jmp find_parameter1_index
   find_parameter1_index_skip :

   ; X should be pointing at one of our targets
   ; Grab the data out of there
   ld temp, X+ ; grab the low byte out of the array
   std Y+1, temp ; store it at Y+1
   ld temp, X+ ; grab the high byte out of the array
   std Y+2, temp ; store it at Y+2

   ; Reset X pointer
   ldi r26, low(testArray)
   ldi r27, high(testArray)
   
   ldi counter, 0
   ; Go forward "parameter2" indexes
   find_parameter2_index :
   cp counter, parameter2 ; pre-condition guard
   brlt find_parameter2_index_skip
      adiw r26, 1 ; increment the poiner
	  inc counter
	  jmp find_parameter2_index
   find_parameter2_index_skip :

   ; X should be pointing at our other target
   ; Grab the data out of there
   ld temp, X+ ; Grab the low byte
   std Y+3, temp ; Write to Y+3
   ld temp, X- ; setting pointer back 1, ready to write in other value
   std Y+4, temp ; Write to Y+4

   ; Write the replacement info in from Y+1, Y+2 to parameter2's index
   ld temp, Y+1 ; Grab low byte data from Y+1
   st X+, temp ; Write it to X
   ld temp, Y+2 ; Grab high byte data from Y+2
   st X+, temp ; Write it to X

   ; Write the replacement info in from Y+3, Y+4 to parameter1's index
   ldi temp, Y+3 ; Grab low byte data from Y+3
   st Z+, temp ; Write it to the place we remembered in pointer Z 
               ; (refer to first loop that searches for the index)
   ldi temp, Y+4 ; Grab high byte data from Y+4
   st Z+, temp ;

   

   
   

