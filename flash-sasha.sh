#! /bin/bash

./build-saxa.sh && avrdude -c usbasp-clone -p t2313a -U flash:w:main-saxa.hex:a
