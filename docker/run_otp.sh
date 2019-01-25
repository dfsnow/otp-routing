#!/bin/bash

# Create the OTP graph object if none exits
if [ ! -f $WORKING_DIR\graphs/$GEOID/Graph.obj ]; then
    java -Xmx24G \
        -jar /otp/otp-$OTP_VERSION-shaded.jar \
        --cache $WORKING_DIR \
        --basePath $WORKING_DIR \
        --build $WORKING_DIR\graphs/$GEOID
fi

# Create the OTP matrix
java -Xmx24G \
    -jar /otp/jython-standalone-$JYTHON_VERSION.jar \
    -Dpython.path=/otp/otp-$OTP_VERSION-shaded.jar \
    /otp/create_otp_matrix.py
