FROM openjdk:8 

ENV OTP_VERSION 1.3.0
ENV JYTHON_VERSION 2.7.1

RUN mkdir -p /otp/ && \
    mkdir -p /resources/graphs && \
    mkdir -p /resources/outputs

RUN wget https://repo1.maven.org/maven2/org/python/jython-standalone/$JYTHON_VERSION/jython-standalone-$JYTHON_VERSION.jar \
-O /otp/jython-standalone-$JYTHON_VERSION.jar && \
wget https://repo1.maven.org/maven2/org/opentripplanner/otp/$OTP_VERSION/otp-$OTP_VERSION-shaded.jar -O /otp/otp-$OTP_VERSION-shaded.jar

COPY create_otp_matrix.py run_otp.sh /otp/
RUN chmod +x /otp/run_otp.sh

CMD ["/bin/bash", "-c", "/otp/run_otp.sh"] 

