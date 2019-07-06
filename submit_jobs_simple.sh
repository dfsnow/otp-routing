#!/bin/bash

docker run -it --rm \
    -v /home/$USER/resources/graphs/:/resources/graphs/ \
    -v /home/$USER/resources/outputs/:/resources/outputs/ \
    -e TRAVEL_MODE='CAR' \
    -e TYPE='TRACT' \
    -e OVERWRITE_GRAPH='TRUE' \
    -e MAX_TRAVEL_TIME=3600 \
    -e MAX_WALK_DIST=3000 \
    -e CHUNKS=100 \
    -e MAX_THREADS=12 \
    -e GEOID=17031 \
    snowdfs/otp-routing

