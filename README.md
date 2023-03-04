# LED-PWM

A program for `ATTiny2313` for controlling LED brightness using a rotary encoder.


## Pins

``` 
                           ATTiny 2313
                           ┌───┐ ┌───┐
            (RESET/dW) PA2─┤1  ╰─╯ 20├─VCC
                 (RXD) PD0─┤2      19├─PB7 (UCSK/SCL/PCINT7)
                 (TXD) PD1─┤3      18├─PB6 (MISO/DO/PCINT6)
               (XTAL2) PA1─┤4      17├─PB5 (MOSI/DI/SDA/PCINT5)
               (XTAL1) PA0─┤5      16├─PB4 (OC1B/PCINT4)
Encoder CLK  →  (INT0) PD2─┤6      15├─PB3 (OC1A/PCINT3)  →  LED
Encoder DT   →  (INT1) PD3─┤7      14├─PB2 (OC0A/PCINT2)
                  (T0) PD4─┤8      13├─PB1 (AIN1/PCINT1)
             (OC0B/T1) PD5─┤9      12├─PB0 (AIN0/PCINT0)
Encoder GND  →         GND─┤10     11├─PD6 (ICP)
                           └─────────┘
```

## Opeartion

16-bit PWM channel A is used in Fast PWM 9-bit mode.

