#!/bin/bash

docker run --rm \
    -v ~/resources/graphs/:/resources/graphs/ \
    -v ~/resources/outputs/:/resources/outputs/ \
    -e TRAVEL_MODE='TRANSIT,WALK' \
    -e TYPE='TRACT' \
    -e OVERWRITE_GRAPH='TRUE' \
    -e MAX_TRAVEL_TIME=7200 \
    -e MAX_WALK_DIST=3000 \
    -e CHUNKS=100 \
    -e MAX_THREADS=4 \
    -e GEOID=48029 \
    snowdfs/otp-routing

