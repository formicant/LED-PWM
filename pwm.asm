; ATTiny2313 constants
.include "tn2313def.inc"

; TCCR1A modes
.equ pwm_clear  = (1<<COM1A1)
.equ pwm_8bit   = (1<<WGM10)
.equ pwm_9bit   = (1<<WGM11)
.equ pwm_10bit  = (1<<WGM10) | (1<<WGM11)
.equ pwm_icr_a  = (1<<PWM11)
; TCCR1B modes
.equ pwm_icr_b  = (1<<WGM13)
.equ pwm_fast   = (1<<WGM12)
.equ pwm_scale1 = (1<<CS10)


; Port B output pins
.equ led_pwm       = (1<<PORTB3)
.equ output_mask_b = led_pwm

; Port D input pins
.equ encoder_clk   = (1<<PIND2)
.equ encoder_dt    = (1<<PIND3)
.equ encoder_mask  = encoder_clk | encoder_dt
.equ output_mask_d = 0  ; all pins are inputs

; Constants
.equ bounce_period = 100  ; µs
.equ sleep_time  =  3500  ; times ~290 µs = ~1 s

; Register aliases
.def zero  = r16
.def tmp   = r17
.def input = r18
.def count = r19
.def level = r20


; Interrupt vector table
    rjmp reset  ; RES  Reset
    rjmp wakeup ; INT0 External Interrupt Request 0
    rjmp wakeup ; INT1 External Interrupt Request 1
    reti        ; ICP1 Timer/Counter1 Capture Event
    reti        ; OC1A Timer/Counter1 Compare Match A
    reti        ; OVF1 Timer/Counter1 Overflow
    reti        ; OVF0 Timer/Counter0 Overflow
    reti        ; URXC USART, Rx Complete
    reti        ; UDRE USART Data Register Empty
    reti        ; UTXC USART, Tx Complete
    reti        ; ACI  Analog Comparator
    reti        ; PCI0 Pin Change Interrupt Request 0
    reti        ; OC1B Timer/Counter1 Compare Match B
    reti        ; OC0A Timer/Counter0 Compare Match A
    reti        ; OC0B Timer/Counter0 Compare Match B
    reti        ; USI_START USI Start Condition
    reti        ; USI_OVF   USI Overflow
    reti        ; ERDY EEPROM Ready
    reti        ; WDT  Watchdog Timer Overflow
    reti        ; PCI1 Pin Change Interrupt Request 1
    reti        ; PCI2 Pin Change Interrupt Request 2


; PWM level table
levels:
.include "levels.asm"
levels_end:
.equ level_count = levels_end - levels


; Program starts here after reset
reset:
    ; disable interrupts
    cli

    ; initialize stack
    ldi  tmp, low(RAMEND)
    out  SPL, tmp

    ; initialize input ports with pull-up resistors
    ldi  tmp, ~output_mask_b
    out  PORTB, tmp
    ldi  tmp, ~output_mask_d
    out  PORTD, tmp

    ; initialize output ports
    ldi  tmp, output_mask_b
    out  DDRB, tmp
    ldi  tmp, output_mask_d
    out  DDRD, tmp

    ; initizlize power consumption (ATTiny2313A only)
    ; ldi  tmp, (1<<PRUSART) | (1<<PRUSI) | (1<<PRTIM0)
    ; out  PRR, tmp

    ; initialize interrupt mask
    ldi  tmp, (1<<INT0) | (1<<INT1)
    out  GIMSK, tmp

    ; initialize PWM timer
    ; fast PWM mode, no clock prescaling
    ldi  tmp, pwm_fast | pwm_scale1
    out  TCCR1B, tmp

    ; initialize register values
    clr  zero
    clr  count
    clr  level

    ; start with PWM turned off
    rjmp turn_off


set_level:
    ; get address in the level table
    ; addr = 2 * (levels + level)
    ldi  ZL, low (2 * levels)
    ldi  ZH, high(2 * levels)
    add  ZL, level
    adc  ZH, zero
    add  ZL, level
    adc  ZH, zero
    ; get level value from the table
    lpm  XL, Z+
    lpm  XH, Z
    ; set PWM value
    out  OCR1AH, XH
    out  OCR1AL, XL

input_loop:
    ; wait until both encoder pins are active (low signal) for bounce_period
    ; or until nothing happens during sleep_time
    ldi  YL, low  (sleep_time)
    ldi  YH, high (sleep_time)

sleep_check:
    ldi  XL, low (bounce_period)
    ldi  XH, high(bounce_period)
    dec  count
    brne encoder_turning_debounce
    sbiw YL, 1  ; dec Y
    breq go_to_sleep

encoder_turning_debounce:
    in   input, PIND
    andi input, encoder_mask
    brne sleep_check
    sbiw XL, 1  ; dec X
    nop  ; to make debouncing loop take 8 cycles = 1 µs
    brne encoder_turning_debounce

encoder_turning:
    ; wait until one of the encoder pins is inactive (high signal) for bounce_period
    ldi  XL, low (bounce_period)
    ldi  XH, high(bounce_period)

encoder_turned_debounce:
    in   input, PIND
    andi input, encoder_mask
    breq encoder_turning
    sbiw XL, 1  ; dec X
    nop  ; to make debouncing loop take 8 cycles = 1 µs
    brne encoder_turned_debounce

encoder_turned:
    ; determine which direction the encoder is turned
    cpi  input, encoder_dt
    breq clockwise
    cpi  input, encoder_clk
    brne input_loop

counter_clockwise:
    ; decrement level if possible
    tst  level
    breq input_loop
    dec  level
    ; if level is 0, turn off PWM
    brne set_level

turn_off:
    out  TCCR1A, zero
    out  PORTB, zero
    rjmp input_loop

clockwise:
    ; if level was 0, turn on PWM
    tst  level
    brne increment_level

turn_on:
    ldi  tmp, pwm_clear | pwm_8bit
    out  TCCR1A, tmp

increment_level:
    ; increment level if possible
    cpi  level, level_count - 1
    breq input_loop
    inc  level
    rjmp set_level


; Activate the controller's sleep mode
go_to_sleep:
    ldi  tmp, (1<<SE)   ; enable sleep mode
    tst  level          ; if level != 0
    brne set_sleep_mode ;   then, idle sleep mode
    ori  tmp, (1<<SM0)  ;   else, power-down sleep mode
set_sleep_mode:
    out  MCUCR, tmp
    ; enable interrupts to wake up when the encoder is turned
    sei
    sleep
    rjmp input_loop


; Wake up from sleep when the encoder sends a signal
wakeup:
    cli  ; disable interrupts
    out  MCUCR, zero
    reti


