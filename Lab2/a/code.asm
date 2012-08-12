;DEFINITIONS

; while (( dividend > divisor) && !( divisor & 0x8000)) {

   ldi divisor_high, divisor_high << 1
   ldi divisor_low, divisor_low << 1
   ; CONFIRM CARRY IS OCCURING PROPERLY.


