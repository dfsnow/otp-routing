#!/bin/bash

# Geometry and locations options
GEOID_LIST=17031
GEOMETRY='blocks'

# Chunk and threading options
CHUNKS=200
MAX_THREADS=30

# Directory options
WORKING_DIR='/resources/'
LOCATION_DIR='locations/'

# OTP settings
TRAVEL_MODE='WALK,TRANSIT'  # Options are WALK,TRANSIT,DRIVE
MAX_TRAVEL_TIME=3600  # in seconds
MAX_WALK_DIST=2000  # in meters

# Main loop for running jobs
for GEOID in $GEOID_LIST; do

    loc_dir="./"$WORKING_DIR""$LOCATION_DIR"/$GEOID"
    out_dir="./"$WORKING_DIR"output/$GEOID"

    if [ ! -d $loc_dir ]; then mkdir $loc_dir; fi
    if [ ! -d $out_dir ]; then mkdir $out_dir; fi

    if [ ! -f "$loc_dir/$GEOID-origins.csv" ]; then
        source ./scripts/create_origins_file.sh
    fi

    if [ ! -f "$loc_dir/$GEOID-destinations.csv" ]; then
        source ./scripts/create_destinations_file.sh
    fi

    docker run -it --rm \
        -v /home/snow/otp-routing/resources/:$WORKING_DIR \
        -e WORKING_DIR=$WORKING_DIR \
        -e LOCATION_DIR=$LOCATION_DIR \
        -e TRAVEL_MODE=$TRAVEL_MODE \
        -e MAX_TRAVEL_TIME=$MAX_TRAVEL_TIME \
        -e MAX_WALK_DIST=$MAX_WALK_DIST \
        -e CHUNKS=$CHUNKS \
        -e MAX_THREADS=$MAX_THREADS \
        -e GEOID=$GEOID \
        otp

done
