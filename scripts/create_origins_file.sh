#!/bin/bash

# Extract the required geometry centroids from DB
psql -d network -U snow -c "\COPY (
    SELECT geoid AS GEOID, ST_Y(centroid) AS Y, ST_X(centroid) AS X
    FROM $GEOMETRY
    WHERE ST_Contains((
        SELECT geom_buffer
        FROM counties
        WHERE geoid = '$GEOID'),
        centroid)
    ) TO './"$WORKING_DIR""$LOCATION_DIR"/$GEOID/$GEOID-origins.csv'
    DELIMITER ',' CSV;"

# Split the origins into different CSVs for threading
if [ -n "$CHUNKS" ]; then

    cd ./"$WORKING_DIR""$LOCATION_DIR"/$GEOID/

    tail -n +2 $GEOID-origins.csv > temp.csv
    rows=$(cat temp.csv | wc -l)
    ((chunk_size = ($rows + $CHUNKS - 1) / $CHUNKS))
    split -a ${#CHUNKS} --numeric=1 -l $chunk_size -d temp.csv x
    for chunk in $(seq -f "%0${#CHUNKS}g" 1 $CHUNKS); do
        echo "GEOID,Y,X" > $GEOID-origins-$chunk.csv
        cat x$chunk >> $GEOID-origins-$chunk.csv
    done

    rm x* temp.csv

    cd ../../../
fi

