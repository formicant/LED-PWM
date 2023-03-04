#! /bin/bash

avrdude -c usbasp-clone -p t2313 -U flash:w:pwm.hex:a
