
.equ quotient = 0
.equ dividend = 41352
.equ divisor = 8
.equ mazic = 0x8000 

;.def var = r15
;.def var = r16
;.def var = r17
;.def var = r18
.def temp = r19
.def mazic2 = r20
.def bit_position_low = r21
.def bit_position_high = r22
.def dividend_low = r23
.def dividend_high = r24
.def divisor_low = r25
.def divisor_high = r26
.def quotient_low = r27
.def quotient_high = r28
.def mazic_low = r29
.def mazic_high = r30
.def zero = r31

ldi mazic2, 0x80
ldi bit_position_low, 1
ldi zero, 0
ldi quotient_low, low(quotient)
ldi quotient_high, high(quotient)
ldi dividend_low, low(dividend)
ldi dividend_high, high(dividend)
ldi divisor_low, low(divisor)
ldi divisor_high, high(divisor)
ldi mazic_low, low(mazic)
ldi mazic_high, high(mazic)


start_while1 :

cp dividend_low, divisor_low
cpc dividend_high, divisor_high

brlo skip_while1
  mov temp, divisor_high ; move the high byte of the divisor to temp
  and temp, mazic_high ; AND the temp with the mazic high
  cp temp, mazic_high ; compare the and result, with mazic high

  breq skip_while1

    lsl divisor_low
    rol divisor_high

   lsl bit_position_low
	rol bit_position_high

  jmp start_while1
skip_while1 :

start_while2 :
  cp bit_position_low, zero
  cpc bit_position_high, zero
  breq skip_while2

    cp dividend_low, divisor_low
    cpc dividend_high, divisor_high

    brlo skip_if

      sub dividend_low, divisor_low
      sbc dividend_high, divisor_high

      add quotient_low, bit_position_low
      adc quotient_high, bit_position_high

    skip_if :

    lsr divisor_high
    ror divisor_low

    lsr bit_position_high
	 ror bit_position_low

    jmp start_while2
skip_while2 :


end : jmp end
