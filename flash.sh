#! /bin/bash

avrdude -c usbasp-clone -p t2313a -U flash:w:pwm.hex:a
