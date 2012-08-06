;int i;
;int j;
;int k;

;int A[5][5];
;int B[5][5];
;int C[5][5];

;int main(void) {

;  for (i = 0; i < 5; i++) {

;    for (j = 0; j < 5; j++) {
;      A[i][j] = i + j;
;      B[i][j] = i - j;
;      C[i][j] = 0;
;    }
;  }
;
;  for(i=0;i<5;i++) {
;    for(j=0;j<5;j++) {
;      for(k=0;k<5;k++) {
;        C[i][j] += A[i][k] * B[k][j];
;      }
;    }
;  }
;
;}


.dseg
.org 0x100
A: .byte 25
.cseg

.dseg
.org 0x150
B: .byte 25
.cseg

.dseg
.org 0x200
C: .byte 50
.cseg




ldi r26, low(A)
ldi r27, high(A)
ldi r28, low(B)
ldi r29, high(B)
ldi r30, low(C)
ldi r31, high(C)


.def counter1 = r21
.def counter2 = r22
.def counter3 = r23

.def five = r24
.def zero = r25

ldi five, 5
ldi zero, 0

.def ATemp = r16
.def BTemp = r17
.def CTempLow = r18
.def CTempHigh = r19
.def temp = r20
.def BOffset = r20

main:

  ldi counter1, 0
  for1:

    ldi counter2, 0
    for2:
       mov temp, counter1
    add temp, counter2
       st x+, temp
	   
	   mov temp, counter1
	   sub temp, counter2
	    
	   st y+, temp
	   
	   ldi temp, 0
	   st z+, temp
	   st z+, temp

      inc counter2
      cpi counter2, 5
    brlt for2

    inc counter1
    cpi counter1, 5
  brlt for1

;  for(i=0;i<5;i++) {
;    for(j=0;j<5;j++) {
       
;      for(k=0;k<5;k++) {
;        C[i][j] += A[i][k] * B[k][j];
;      }
;    }
;  }

  ldi r26, low(A)
  ldi r27, high(A)
  ldi r28, low(B)
  ldi r29, high(B)
  ldi r30, low(C)
  ldi r31, high(C) 

  subi r30, 2
  sbc r31, zero

  add r26, five
  adc r27, zero


  ldi BOffset, 0

  ldi counter1, 0
  for3:
    
    ldi counter2, 0
	for4:
      
 

	  ldi r28, low(B)
      ldi r29, high(B)

      add r28, BOffset
      adc r29, zero

      inc BOffset
      cpi BOffset, 6
      

      brlt skipReset
         mov Boffset, zero

		 add r26, five
	     adc r27, zero

      skipReset :

      sub r26, five
	  sbc r27, zero

      cpi counter1, 0
	  brne notStartingIndex
	    cpi counter2, 0
		brne notStartingIndex
		   cpi counter3, 0
		   brne notStartingIndex
		     jmp doWrite
      
	  notStartingIndex :
     
	  cpi Boffset, 1
	  breq skipWrite
         
        doWrite :

        st z+, CTempLow
	    st z+, CTempHigh
        
      skipWrite :

      mov CTempLow, zero
	  mov CTempHigh, zero


      ldi counter3, 0
	  for5:
	    
		ld ATemp, x+
		ld BTemp, y    
        add r28, five
		adc r29, zero

        muls Atemp, BTemp
		add CTempLow, r0
		adc CTempHigh, r1
;       C[i][j] += A[i][k] * B[k][j]


        inc counter3
        cpi counter3, 5
      brlt for5

      inc counter2
      cpi counter2, 6
    brlt for4

    inc counter1
    cpi counter1, 5
  brlt for3

endmain: jmp endmain