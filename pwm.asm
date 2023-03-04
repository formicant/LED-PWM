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
.equ led_debug     = (1<<PORTB2)
.equ output_mask_b = led_pwm | led_debug

; Port D input pins
.equ encoder_clk   = (1<<PIND2)
.equ encoder_dt    = (1<<PIND3)
.equ encoder_mask  = encoder_clk | encoder_dt
.equ output_mask_d = 0  ; all pins are inputs

; Constants
; .equ pwm_period = 512
; (custom PWM periods are not supported by VMLAB emulator)
.equ bounce_period = 1000  ; microseconds

; Register aliases
.def zero  = r16
.def tmp   = r17
.def input = r18
.def level = r19


; Interrupt vector table
    rjmp reset      ; RES  Reset
    reti            ; INT0 External Interrupt Request 0
    reti            ; INT1 External Interrupt Request 1
    reti            ; ICP1 Timer/Counter1 Capture Event
    reti            ; OC1A Timer/Counter1 Compare Match A
    reti            ; OVF1 Timer/Counter1 Overflow
    reti            ; OVF0 Timer/Counter0 Overflow
    reti            ; URXC USART, Rx Complete
    reti            ; UDRE USART Data Register Empty
    reti            ; UTXC USART, Tx Complete
    rjmp comparator ; ACI  Analog Comparator
    reti            ; PCI
    reti            ; OC1B
    reti            ; OC0A
    reti            ; OC0B
    reti            ; USI_START USI Start Condition
    reti            ; USI_OVF   USI Overflow
    reti            ; ERDY
    reti            ; WDT  Watchdog Timer Overflow


; PWM level table
; quadratic curve, 32 levels
levels:
    .dw  0     ; off
    .dw  0     ; minimum
    .dw  1
    .dw  2
    .dw  5
    .dw  9
    .dw  14
    .dw  20
    .dw  28
    .dw  36
    .dw  46
    .dw  57
    .dw  69
    .dw  82
    .dw  96
    .dw  111
    .dw  128
    .dw  145
    .dw  164
    .dw  184
    .dw  205
    .dw  227
    .dw  250
    .dw  275
    .dw  300
    .dw  327
    .dw  355
    .dw  384
    .dw  414
    .dw  445
    .dw  478
    .dw  511   ; maximum
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

    ; initialize analog comparator
    ; enable interrupt by both rising and falling edges
    ;ldi  tmp, (1<<ACIE)
    ;out  ACSR, tmp
    ; disable digital input on analog comparator pins
    ;ldi  tmp, (1<<AIN0D) | (1<<AIN1D)
    ;out  DIDR, tmp
    ; enable interupts
    ;sei

    ; initialize PWM timer

    ; (custom PWM periods are not supported by VMLAB emulator.
    ; New ATTiny2313A models should support this)
    ; ldi  XL, low (pwm_period - 1)
    ; ldi  XH, high(pwm_period - 1)
    ; out  ICR1H, XH
    ; out  ICR1L, XL

    ; fast PWM mode, no clock prescaling
    ldi  tmp, pwm_fast | pwm_scale1
    out  TCCR1B, tmp
    ; set on start, clear on match, 9-bit PWM
    ldi  tmp, pwm_clear | pwm_9bit
    out  TCCR1A, tmp

    ; initialize register values
    clr  zero
    clr  level

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
    ldi  XL, low (bounce_period)
    ldi  XH, high(bounce_period)

encoder_turning_debounce:
    in   input, PIND
    andi input, encoder_mask
    brne input_loop
    sbiw XL, 1
    nop  ; debouncing loop takes 8 cycles = 1 us
    brne encoder_turning_debounce

encoder_turning:
    ; wait until one of the encoder pins is inactive (high signal) for bounce_period
    ldi  XL, low (bounce_period)
    ldi  XH, high(bounce_period)

encoder_turned_debounce:
    in   input, PIND
    andi input, encoder_mask
    breq encoder_turning
    sbiw XL, 1
    nop  ; debouncing loop takes 8 cycles = 1 us
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
    clr  tmp
    out  TCCR1A, tmp
    out  PORTB, tmp
    rjmp input_loop

clockwise:
    ; if level was 0, turn on PWM
    tst  level
    brne increment_level

turn_on:
    ldi  tmp, pwm_clear | pwm_9bit
    out  TCCR1A, tmp

increment_level:
    ; increment level if possible
    cpi  level, level_count - 1
    breq input_loop
    inc  level
    rjmp set_level


; Analog comparator interrupt
comparator:
    ; send comparator output to led_debug
    in   tmp, ACSR
    bst  tmp, ACO
    clr  tmp
    bld  tmp, PORTB2
    out  PORTB, tmp
    reti

