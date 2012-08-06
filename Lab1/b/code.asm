;unsigned int n;
;void main(void) {
;   n = 0; // Total sum
 
;   for(i = 0;(s[i] >= ’0’) && (s[i] <= ’9’);i++) { // Verify integral
;      n = 10 * n + (s[i] - ’0’); // Multiply weight (10), Add value
;   }
 
;}
 
.equ size = 6
.equ asciiOffset = 48
 
.def multiplierLowLow = r16
.def multiplierLowHigh = r17
.def multiplierHighLow = r18
.def multiplierHighHigh = r19
 
.def ZERO = r20
.def multiplyCounter = r21
.def counter = r22
.equ nine = 9
.def char = r24
.def resultPointer = r25
.def resultLowLow = r26
.def resultLowHigh = r27
.def resultHighLow = r28
.def resultHighHigh = r29
.def sourcePointer = r30
 
.dseg
.org 0x100
result: .byte 4
.cseg
 
sourceString: .db "323232"
ldi sourcePointer, low(sourceString)
ldi resultLowLow, low(result)
 
clr counter
 
sts 0x100, ZERO
sts 0x101, ZERO
sts 0x102, ZERO
sts 0x103, ZERO
 
main:
        lpm char, z+
        ; convert char to the actual integral
        subi char, asciiOffset
 
        ; grab from memory
        lds resultLowLow, 0x103
        lds resultLowHigh, 0x102
        lds resultHighLow, 0x101
        lds resultHighHigh, 0x100
 
        ; multiply by 10
        clr multiplyCounter
        mov multiplierLowLow, resultLowLow
        mov multiplierLowHigh, resultLowHigh
        mov multiplierHighLow, resultHighLow
        mov multiplierHighHigh, resultHighHigh
 
        multiply:
                bclr 0 
                add resultLowLow, multiplierLowLow
                adc resultLowHigh, multiplierLowHigh
                adc resultHighLow, multiplierHighLow
                adc resultHighHigh, multiplierHighHigh
 
                inc multiplyCounter
                cpi multiplyCounter, nine
                brlt multiply
 
        ; add char onto it
        add resultLowLow, char
        adc resultLowHigh, ZERO
        adc resultHighLow, ZERO
        adc resultHighHigh, ZERO
 
        ; write back to memory
        sts 0x103, resultLowLow
        sts 0x102, resultLowHigh
        sts 0x101, resultHighLow
        sts 0x100, resultHighHigh
 
        inc counter
        cpi counter, size
        brlt main
 
loop: nop
        rjmp loop