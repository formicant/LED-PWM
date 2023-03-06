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
Encoder DT   →  (INT1) PD3─┤7      14├─PB2 (OC0A/PCINT2)  →  Debug LED
                  (T0) PD4─┤8      13├─PB1 (AIN1/PCINT1)  ←  Comparator -
             (OC0B/T1) PD5─┤9      12├─PB0 (AIN0/PCINT0)  ←  Comparator +
Encoder GND  →         GND─┤10     11├─PD6 (ICP)
                           └─────────┘
```


## Fuses

- **Low:** `E4` (modified)
  |   fuse | bits | value |  state   | description
  |-------:|:----:|:-----:|:--------:|:------------
  | CKDIV8 |    7 |    1  | modified | 8× prescaling disabled
  |  CKOUT |    6 |    1  | default  | clock output disabled
  |    SUT | 5..4 |   10  | default  | slowly rising power
  |  CKSEL | 3..0 | 0100  | default  | internal RC oscillator 8 MHz
  
- **High:** `DF` (default)
  |     fuse | bits | value |  state   | description
  |---------:|:----:|:-----:|:--------:|:------------
  |     DWEN |    7 |    1  | default  | debugWire disabled
  |   EESAVE |    6 |    1  | default  | do not preserve EEPROM when flashing
  |    SPIEN |    5 |    0  | default  | serial programming enabled
  |    WDTON |    4 |    1  | default  | watchdog safety level 1
  | BODLEVEL | 3..1 |  111  | default  | BOD disabled
  | RSTDISBL |    0 |    1  | default  | reset enabled
  
- **Extended:** `FF` (default)
  |      fuse | bits |  value  |  state   | description
  |----------:|:----:|:-------:|:--------:|:------------
  | (unused)  | 7..1 | 1111111 | default  | 
  | SELFPRGEN |    0 |       1 | default  | self-programming disabled

Fuse programming:
``` bash
avrdude -c usbasp-clone -p t2313 -B 250kHz -U lfuse:w:0xE4:m
```


## Opeartion

16-bit PWM channel A is used in Fast PWM 9-bit mode.


