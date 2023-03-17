#! /bin/bash

avrdude -c usbasp-clone -p t2313 -B 250kHz -U lfuse:w:0xE4:m
