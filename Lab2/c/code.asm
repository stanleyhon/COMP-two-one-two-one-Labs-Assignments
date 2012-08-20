.include "m64def.inc"

.def returnValue = r16
.def parameter1 = r16
.def parameter2 = r17
.def counter = r18
.def temp = r18
.def pivot_low = r19
.def pivot_high = r20
.def i = r21
.def j = r22
.def arrayTemp_low = r23
.def arrayTemp_high = r24
.def p = r25
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



; This macro writes array values to SRAM
.macro writeToArray
	ldi r16, low(@0)
	ldi r17, high(@0)
	st X+, r16
	st X+, r17
	clr r16
	clr r17
.endmacro

ldi r26, low(testArray)
ldi r27, high(testArray)

.macro gotoIndex ;@0 Register @1 increment Z
   ldi counter, 0
   ; Go forward "parameter" indexes
   find_parameter_index :
   cp counter, @0 ; pre-condition guard
   breq find_parameter_index_skip
      adiw r26, 2 ; increment the poiner
      
      push counter
      ldi temp, @1
      cpi temp, 1
	  brne skipIncrementZ
         adiw r30, 2
	  skipIncrementZ :
      pop counter

	  inc counter
	  jmp find_parameter_index
   find_parameter_index_skip :
.endmacro

.macro pushPointers ;@0 X @1 Y @3 Z
   ldi temp, 1
   cpi temp, @0
   brne skipIncrementX
      push r26
      push r27
   skipIncrementX :
   
   cpi temp, @1
   brne skipincrementY
      push r28
      push r29
   skipincrementY :

   cpi temp, @2
   brne skipIncrementZ
      push r30
      push r31      
   skipIncrementZ :
.endmacro

.macro popPointers ;@0 X @1 Y @3 Z
   ldi temp, 1
   
   cpi temp, @2
   brne skipIncrementZ
      pop r31
      pop r30      
   skipIncrementZ :

   cpi temp, @1
   brne skipincrementY
      pop r29
      pop r28
   skipincrementY :

   cpi temp, @0
   brne skipIncrementX
      pop r27
      pop r26
   skipIncrementX :

.endmacro

.macro readFromArray ; @0 index to read from, @1, @2 registers to put result in
   ldi r26, low(testArray) ; grab a handle to the array
   ldi r27, high(testArray)

   gotoIndex @0, 0 ; set X pointer to that index, don't change Z
   ld temp, X+ ; grab the low byte out
   mov @1, temp
   ld temp, X+ ; grab the high byte out
   mov @2, temp
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
   ; #Test#: Swaps index 0 with index 9. [pass]
   ;ldi r16, 0
   ;ldi r17, 9
   ;rcall swapArrayIndexes
   ; #Test#: Reads from index 2 into r24, r25 [pass]
   ;ldi r16, 2
   ;readFromArray r16, r24, r25
   ; #Test#: Partition behaviour test
  /*
   ldi parameter1, 0
   ldi parameter2, 9
   rcall partition
   ldi parameter1, 0
   ldi parameter2, 5
   rcall partition
   ldi parameter1, 0
   ldi parameter2, 2
   rcall partition
   ldi parameter1, 0
   ldi parameter2, 1
   rcall partition
   ldi parameter1, 4
   ldi parameter2, 5
   rcall partition
   ldi parameter1, 7
   ldi parameter2, 9
   rcall partition
*/
   ldi parameter1, 0
   ldi parameter2,9
   rcall quicksort

   loop: nop
   jmp loop

quicksort:
   pushPointers 1, 1, 1

   in r28, SPL
   in r29, SPH
   sbiw r28, 10

   out SPH, r29
   out SPL, r28


   cp parameter1, parameter2
   brge skip_sorting ; if p >= r, skip
   
      push parameter2 ;stack: r
	  push parameter1 ;stack: p,r
	  rcall partition ; return value stored in "returnValue" (r16)
	  
	  mov parameter2, returnValue ;set @2
	  pop parameter1 ;set @1, stack: r
	  push parameter2 ; push q onto stack, stack: q,r
      dec parameter2 ; q=q-1

	  rcall quicksort ;quicksort(array,p,q-1)

      pop parameter1 ;set @1, stack: r
      inc parameter1 ;q=q+1

      pop parameter2 ;set @2, stack: empty     

	  rcall quicksort ; quicksort(array,q+1,r)

   skip_sorting :
    
   adiw r28, 10
   out SPH, r29
   out SPL, r28
   popPointers 1, 1, 1
   ret

partition:
   pushPointers 1, 1, 1
   
   in r28, SPL
   in r29, SPH
   sbiw r28, 10

   out SPH, r29
   out SPL, r28

   mov p, parameter1
   ; stores array[parameter1] into pivot
   readFromArray parameter1, pivot_low, pivot_high 
   
   mov i, parameter1
   
   mov j, parameter2
   inc j
   
   infinite_loop :
      inc_i :
         inc i
	     readFromArray i, arrayTemp_low, arrayTemp_high ; read array[i] into arrayTemp
	     cp pivot_low, arrayTemp_low
	     cpc pivot_high, arrayTemp_high
	     brlt skip_inc_i ; array[i] <= pivot ; #### SUSPECT COMPARISON ####
	        cp parameter2, i
		    brlt skip_inc_i ; i <= r ; #### SUSPECT COMPARISON ####
		       jmp inc_i
	  skip_inc_i :
	  
	  inc_j :
	     dec j
         readFromArray j, arrayTemp_low, arrayTemp_high ; read array[i] into arrayTemp
         cp pivot_low, arrayTemp_low
	     cpc pivot_high, arrayTemp_high
	     brpl skip_inc_j ; #### SUSPECT COMPARISON ####
            jmp inc_j
      skip_inc_j :

	  cp i, j
	  brge skip_infinite_loop

	  ; swap array[i] and array[j]
	  mov parameter1, i
	  mov parameter2, j
	  rcall swapArrayIndexes 
	  jmp infinite_loop
   skip_infinite_loop :

   
   mov parameter1, p
   mov parameter2, j

   rcall swapArrayIndexes
   
   mov returnValue, j

   adiw r28, 10
   out SPH, r29
   out SPL, r28
   popPointers 1, 1, 1
   ret

; This function swaps the two array indexes
; Frame Contents:
; Y+1,Y+2 - array[parameter1]
; Y+3,Y+4 - array[parameter2]
; Frame size:
; 2 bytes to save X
; 2 bytes to save Y
; 2 bytes to save Z
swapArrayIndexes:
   pushPointers 1, 1, 1
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

   gotoIndex parameter1, 1

   ; X should be pointing at one of our targets
   ; Grab the data out of there
   ld temp, X+ ; grab the low byte out of the array
   std Y+1, temp ; store it at Y+1
   ld temp, X+ ; grab the high byte out of the array
   std Y+2, temp ; store it at Y+2

   ; Reset X pointer
   ldi r26, low(testArray)
   ldi r27, high(testArray)
   
   gotoIndex parameter2, 0

   ; X should be pointing at our other target
   ; Grab the data out of there
   ld temp, X+ ; Grab the low byte
   std Y+3, temp ; Write to Y+3
   ld temp, X ; setting pointer back 1, ready to write in other value
   std Y+4, temp ; Write to Y+4

   sbiw r26, 1

   ; Write the replacement info in from Y+1, Y+2 to parameter2's index
   ldd temp, Y+1 ; Grab low byte data from Y+1
   st X+, temp ; Write it to X
   ldd temp, Y+2 ; Grab high byte data from Y+2
   st X+, temp ; Write it to X

   ; Write the replacement info in from Y+3, Y+4 to parameter1's index
   ldd temp, Y+3 ; Grab low byte data from Y+3
   st Z+, temp ; Write it to the place we remembered in pointer Z 
               ; (refer to first loop that searches for the index)
   ldd temp, Y+4 ; Grab high byte data from Y+4
   st Z+, temp ;

   adiw r28, 10
   out SPH, r29
   out SPL, r28
   popPointers 1, 1, 1
   ret


