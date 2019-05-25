#!/bin/bash

input_dir="/resources/graphs/"$GEOID""
output_dir="/resources/outputs/"$GEOID""
zipped_dir="/resources/zipped/"

mkdir -p $input_dir
mkdir -p $output_dir

if [ ! -f $input_dir/$GEOID-origins.csv ]; then
    tar -xvzf $zipped_dir/$GEOID.tar.gz --strip-components=3 -C $input_dir
fi

# Split the origins into different CSVs for threading
tail -n +2 $input_dir/$GEOID-origins.csv > /tmp/temp.csv
rows=$(cat /tmp/temp.csv | wc -l)
((chunk_size = ($rows + $CHUNKS - 1) / $CHUNKS))
split -a ${#CHUNKS} --numeric=1 -l $chunk_size -d /tmp/temp.csv /tmp/x
for chunk in $(seq -f "%0${#CHUNKS}g" 1 $CHUNKS); do
    echo "GEOID,Y,X" > /tmp/$GEOID-origins-$chunk.csv
    cat /tmp/x$chunk >> /tmp/$GEOID-origins-$chunk.csv
done

rm /tmp/x* /tmp/temp.csv

# Create the OTP graph object if none exits
if [ ! -f $input_dir/Graph.obj ]; then
    java -Xmx24G \
        -jar /otp/otp-$OTP_VERSION-shaded.jar \
        --cache /resources/ \
        --basePath /resources/ \
        --build $input_dir
fi

# Create the OTP matrix
java -Xmx24G \
    -jar /otp/jython-standalone-$JYTHON_VERSION.jar \
    -Dpython.path=/otp/otp-$OTP_VERSION-shaded.jar \
    /otp/create_otp_matrix.py

rm /tmp/$GEOID-origins-*

awk 'FNR==1 && NR!=1{next;}{print}' \
    /tmp/$GEOID-output-*.csv \
    > $output_dir/$GEOID-output-$TRAVEL_MODE.csv

pbzip2 -f $output_dir/$GEOID-output-$TRAVEL_MODE.csv
