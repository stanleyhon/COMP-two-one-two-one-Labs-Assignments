.include "m64def.inc"

;.def var = r16
;.def var = r17
;.def var = r18
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
; Frame size:
; 2 bytes to hold temporary value for swap
; 2 bytes to hold pointer to point to target 1
; 2 bytes to hold pointer to point to target 2
; 2 bytes to save X
; 2 bytes to save Y
swapArrayIndexes:
   push r28 ; Save SPL
   push r29 ; Save SPH
   push r26 ; Save X low
   push r27 ; Save X high
   sbiw r28, 10

   out SPH, r29
   out SPL, r28
