<<<<<<< HEAD
; INSERT ASSEMBLY AWESOMENESS HERE

; powering.
; x^3 = x * x * x
; the term must be 1 Byte as defined in Q...
; 
=======
.equ CONST_x = 8
.equ CONST_n = 4

.def counter3 = r16
.def i = r17
.def sum_low = r18
.def sum_middle = r19
.def sum_high = r20
.def num = r21
.def counter = r22
.def a = r23
.def result_low = r24
.def result_high = r25
.def temp_low = r26 
.def temp_high = r27
.def para1 = r28 
.def para0 = r29
.def counter2 = r30
.def zero = r31


; ###############################################################
; ############# M  A  C  R  O  S  T  Y  L  E  ###################
; ###############################################################
; ###############################################################
.macro power

; ###############################################################
; ###############################################################
; ############ O  P  A  M  A  C  R  O  S  T  Y  L  E  ###########
; ###############################################################


 ldi i, 0
 ldi result_low, low(1);
 ldi result_high, high(1);

 
 mov para1, @1
 start_for :
 cp i, para1

 ;THIS MAY BE A GAY COMPARISON
 brsh skip_for

   ldi counter, 1
   
   mov temp_low, result_low
   mov temp_high, result_high


   ldi para0, @0
   start_mul :
   cp counter, para0
   breq skip_mul
     
     add result_low, temp_low
	 adc result_high, temp_high

	 ;THIS MAY FUCKING BREAK 
     subi counter, -1

     jmp start_mul	 
   skip_mul :

   subi i, -1
 jmp start_for
 skip_for :
.endmacro


ldi counter2, 0

start_for2 :
cpi counter2, CONST_n
breq skip_for2

  power CONST_x, counter2

  ldi counter3, 0

  start_for3 :
  cp counter3, counter2
  breq skip_for3
    
	add sum_low, result_low
	adc sum_middle, result_high
	adc sum_high, zero

    subi counter3, -1
  jmp start_for3
  skip_for3 :


  subi counter2, -1
jmp start_for2
skip_for2 :









endloop: jmp endloop
>>>>>>> fa1d26878af2f46613fae27b6ecbc19936b7f691
