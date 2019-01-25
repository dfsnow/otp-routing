#!/bin/bash

psql -d network -U snow -c "\COPY (
    SELECT geoid AS GEOID, ST_Y(centroid) AS Y, ST_X(centroid) AS X
    FROM $GEOMETRY
    WHERE ST_Contains((
        SELECT geom_buffer
        FROM counties
        WHERE geoid = '$GEOID'),
        centroid)
    ) TO './"$WORKING_DIR""$LOCATION_DIR"/$GEOID/$GEOID-destinations.csv'
    DELIMITER ',' CSV;"


