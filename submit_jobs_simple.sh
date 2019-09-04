#!/bin/bash

for GEOID in $(cat counties.csv); do

docker run --rm \
    -v ~/resources/graphs/:/resources/graphs/ \
    -v ~/resources/outputs/:/resources/outputs/ \
    -e TRAVEL_MODE='CAR' \
    -e TYPE='TRACT' \
    -e OVERWRITE_GRAPH='TRUE' \
    -e MAX_TRAVEL_TIME=36000 \
    -e MAX_WALK_DIST=5000 \
    -e CHUNKS=100 \
    -e MAX_THREADS=12 \
    -e GEOID=$GEOID \
    snowdfs/otp-routing

done

# blocks 5400 secs travel time, 5000 max walk
# tracts 36000 secs travel time, 5000 max walk

