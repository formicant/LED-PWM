# LED-PWM

A program for `ATTiny2313` to control LED lighting brightness using a rotary encoder.


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


## Fuses

- **Low:** `E4` (modified)
  |   fuse | bits | value |  state   | description
  |-------:|:----:|:-----:|:--------:|:------------
  | CKDIV8 |    7 |     1 | modified | 8× prescaling disabled
  |  CKOUT |    6 |     1 | default  | clock output disabled
  |    SUT | 5..4 |    10 | default  | slowly rising power
  |  CKSEL | 3..0 |  0100 | default  | internal RC oscillator 8 MHz

- **High:** `DF` (default)
  |     fuse | bits | value |  state  | description
  |---------:|:----:|:-----:|:-------:|:------------
  |     DWEN |    7 |     1 | default | debugWire disabled
  |   EESAVE |    6 |     1 | default | do not preserve EEPROM when flashing
  |    SPIEN |    5 |     0 | default | serial programming enabled
  |    WDTON |    4 |     1 | default | watchdog safety level 1
  | BODLEVEL | 3..1 |   111 | default | BOD disabled
  | RSTDISBL |    0 |     1 | default | reset enabled

- **Extended:** `FF` (default)
  |      fuse | bits |  value  |  state  | description
  |----------:|:----:|:-------:|:-------:|:------------
  | (unused)  | 7..1 | 1111111 | default | 
  | SELFPRGEN |    0 |       1 | default | self-programming disabled

To program the fuses, use `fuse.sh`:
``` bash
avrdude -c usbasp-clone -p t2313 -B 250kHz -U lfuse:w:0xE4:m
```


## Flashing

To flash the controller, use `flash.sh`:
```
avrdude -c usbasp-clone -p t2313 -U flash:w:pwm.hex:a
```


## Operation

### PWM

16-bit PWM channel A (pin `PB3`) is used in _Fast PWM_ 8-bit mode to control the LEDs' brightness.
The PWM frequency is 8 Mhz / 2⁸ = 31.25 kHz.

While, an 8-bit PWM could be used instead, 16-bit PWM allows more flexibility if needed.

The PWM levels are defined by the `levels` table locating in `levels.asm` file where each level value takes 2 bytes.
`levels.asm` is generated by `levels.py`.

The true pulse width is by 1 cycle greater than the PWM level value.

The level value 0 does not switch off the LEDs completely. It corresponds to the pulse width of 1 / 256. In order to switch off the LEDs, the program turns off the PWM mode when the level index is 0.

To make the transistor open properly, the minimum pulse width should be about 3 cycles (375 ns), so, the minimal non-zero level value is 2.

[Gamma correction](https://en.wikipedia.org/wiki/Gamma_correction) is used for the level values. The `gamma` value, and`level_count` can be set in `levels.py`.

`level_count` = 23, `gamma` = 2.5:

![level-graph](level-graph.svg)


### Rotary encoder

A rotary encoder is used to change the PWM levels. It is connected to `PD2` and `PD3` pins of the controller.

When inactive, both encoder pins (`clk` and `dt`) have high level (logical one).
The program waits until there's low level (logical zero) on both pins, then determines the rotation direction by noticing which of the pins  turns to logical one first.

In order to mitigate contact bouncing, each signal level on the encoder pins should be kept at least for `debouncing_period` (100 µs).


### Sleep mode

When the encoder is inactive for `sleep_time` (about 1 s), the controller enters the sleep mode.

If the PWM level is 0 (the LEDs are switched off), the deepest _Power Down_ sleep mode is used. Otherwise, the _Idle_ sleep mode is used allowing the PWM to work.

The pins the rotary encoder is connected to (`PD2` and `PD3`) are also used as external interrupt sources (`INT0` and `INT1`) which can wake up the controller from sleep when the decoder is turned.

The interrupts are disabled during normal operation and enabled during sleep.
