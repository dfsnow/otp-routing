#!/bin/bash

input_dir="/resources/graphs/"$GEOID""
output_dir="/resources/outputs/"$GEOID""

mkdir -p $input_dir
mkdir -p $output_dir

# Move the destinations file to tmp dir
cat $input_dir/$GEOID-destinations-$TYPE.csv > /tmp/$GEOID-destinations.csv
export ORIGIN_LENGTH=$(tail -n +2 $input_dir/$GEOID-origins-$TYPE.csv | wc -l)

# Split the origins into different CSVs for threading
# then move it to the tmp dir
tail -n +2 $input_dir/$GEOID-origins-$TYPE.csv > /tmp/temp.csv
rows=$(cat /tmp/temp.csv | wc -l)
((chunk_size = ($rows + $CHUNKS - 1) / $CHUNKS))
split -a ${#CHUNKS} --numeric=1 -l $chunk_size -d /tmp/temp.csv /tmp/x
for chunk in $(seq -f "%0${#CHUNKS}g" 1 $CHUNKS); do
    echo "GEOID,Y,X" > /tmp/$GEOID-origins-$chunk.csv
    if [ -f /tmp/x$chunk ]; then
        cat /tmp/x$chunk >> /tmp/$GEOID-origins-$chunk.csv
    fi
done

rm -f /tmp/x* /tmp/temp.csv

# Creating symlink to the proper pbf file inside the input directory
if [ $TRAVEL_MODE = 'CAR' ]; then
    echo "Using CAR tag extract .pbf file..."
    ln -s -f $input_dir/osm/$GEOID-car.pbf $input_dir/$GEOID.pbf
    echo '{"transit": false}' > $input_dir/build-config.json
else
    echo "Using ALL tag extract .pbf file..."
    ln -s -f $input_dir/osm/$GEOID-all.pbf $input_dir/$GEOID.pbf
fi

# Create the OTP graph object if none exits
if [ $OVERWRITE_GRAPH = 'TRUE' ]; then
    java -Xmx24G \
        -jar /otp/otp-$OTP_VERSION-shaded.jar \
        --cache /resources/ \
        --basePath /resources/ \
        --build $input_dir
fi

# Remove symlink and build-config after graph creation
rm -f $input_dir/$GEOID.pbf $input_dir/build-config.json

# Create the OTP matrix
java -Xmx24G \
    -jar /otp/jython-standalone-$JYTHON_VERSION.jar \
    -Dpython.path=/otp/otp-$OTP_VERSION-shaded.jar \
    /otp/create_otp_matrix.py

# Remove temporary origins and destinations from tmp
rm /tmp/$GEOID-origins-* /tmp/$GEOID-destinations.csv

# Concatenate resulting chunks from each thread
awk 'FNR==1 && NR!=1{next;}{print}' \
    /tmp/$GEOID-output-*.csv \
    > $output_dir/$GEOID-output-$TYPE-$TRAVEL_MODE.csv

# Zip the results matrix into a .bz2
pbzip2 -f $output_dir/$GEOID-output-$TYPE-$TRAVEL_MODE.csv
