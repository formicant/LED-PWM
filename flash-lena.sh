#! /bin/bash

./build-lena.sh && avrdude -c usbasp-clone -p t2313 -U flash:w:main-lena.hex:a
