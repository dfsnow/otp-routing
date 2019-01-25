#!/bin/bash

WORKING_DIR='/resources/'
LOCATION_DIR='locations/'

for x in 17031; do

    docker run -it --rm \
        -v /home/snow/otp-routing/otp/:$WORKING_DIR \
        -e WORKING_DIR=$WORKING_DIR \
        -e LOCATION_DIR=$LOCATION_DIR \
        -e MAX_THREADS=20 \
        -e CHUNKS=200 \
        -e GEOID=$x \
        otp

done
