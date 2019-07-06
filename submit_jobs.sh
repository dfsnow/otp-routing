#!/bin/bash

###### SETUP ######

# Set working directories
GRAPHS_DIR=/home/$USER/resources/graphs/
OUTPUTS_DIR=/home/$USER/resources/outputs/

# Set env variables for running jobs
TRAVEL_MODE='WALK'      # possible travel modes: WALK, TRANSIT, or CAR
TYPE='TRACT'            # possible matrix types: BLOCK or TRACT
OVERWRITE_GRAPH='TRUE'  # overwrite previous OTP Graph.obj: TRUE or FALSE
MAX_TRAVEL_TIME=7200    # maximum travel time before stopping routing (seconds)
MAX_WALK_DIST=3000      # maximum walking distance before stopping (meters)
CHUNKS=100              # number of chunks to split computation across
MAX_THREADS=8           # max number of threads to compute on
MAX_CONTAINERS=2        # max number of containers to run simultaneously


###### SUBMIT JOBS ######

# Create a filename for remaining jobs
remaining_file=$TYPE-$TRAVEL_MODE-remaining.txt

# Get jobs remaining by comparing full county list to output files
# Write remaining jobs to random remaining.txt file
if [ ! -f $remaining_file ]; then
    finished=$(find $OUTPUTS_DIR \
        -iname "*$TYPE*-$TRAVEL_MODE*" \
        -printf "%f\n" \
        | grep -Eo '[[:digit:]]{5,}' \
        | sort)

    comm -13 \
        <(echo $finished ) \
        <(ls $GRAPHS_DIR | sort) \
        > $remaining_file
fi

echo "For TYPE = $TYPE and TRAVEL_MODE = $TRAVEL_MODE"
echo "There are $(cat $remaining_file | wc -l) counties remaining"

# While there are less than N containers running, spin up more
while [ $(cat $remaining_file | wc -l) ]; do
    while [ $(docker ps | wc -l) -lt $MAX_CONTAINERS ]; do

    # Get last line of remaining.txt file
    GEOID=$(awk '/./{line=$0} END{print line}' $remaining_file)
    echo "Now running GEOID: $GEOID"

    # Run job
    docker run -d -it --rm \
        -v $GRAPHS_DIR:/resources/graphs/ \
        -v $OUTPUTS_DIR:/resources/outputs/ \
        -e TRAVEL_MODE=$TRAVEL_MODE \
        -e TYPE=$TYPE \
        -e OVERWRITE_GRAPH=$OVERWRITE_GRAPH \
        -e MAX_TRAVEL_TIME=$MAX_TRAVEL_TIME \
        -e MAX_WALK_DIST=$MAX_WALK_DIST \
        -e CHUNKS=$CHUNKS \
        -e MAX_THREADS=$MAX_THREADS \
        -e GEOID="$GEOID" \
        snowdfs/otp-routing

    # Remove last line of remaining.txt file
    sed -i '$ d' $remaining_file

    done
done
