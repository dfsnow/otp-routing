#!/bin/bash

# Main loop for running jobs
for GEOID in 17031; do

    docker run -it --rm \
        -v /home/"$USER"/resources/graphs/:/resources/graphs/ \
        -v /home/"$USER"/resources/outputs/:/resources/outputs/ \
        -e TRAVEL_MODE='WALK,TRANSIT'\
        -e MAX_TRAVEL_TIME=3600 \
        -e MAX_WALK_DIST=3000 \
        -e CHUNKS=100 \
        -e MAX_THREADS=16 \
        -e GEOID="$GEOID" \
        otp-routing

done
