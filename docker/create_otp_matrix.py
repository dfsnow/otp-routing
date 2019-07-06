#!/usr/bin/jython
from org.opentripplanner.scripting.api import OtpsEntryPoint
from time import sleep
import threading
import datetime
import time
import os
import gc
import sys

gc.collect()

# Importing the current county and config vars
tmp_dir = '/tmp/'
input_dir = '/resources/graphs/'
output_dir = '/resources/outputs/'

# Importing vars for OTP options
geoid = str(os.environ.get('GEOID'))
travel_mode = str(os.environ.get('TRAVEL_MODE'))
max_travel_time = int(os.environ.get('MAX_TRAVEL_TIME'))
max_walk_dist = int(os.environ.get('MAX_WALK_DIST'))
origin_length = int(os.environ.get('ORIGIN_LENGTH'))

# Setup for threading
chunks = int(os.environ.get('CHUNKS'))
max_threads = int(os.environ.get('MAX_THREADS'))

# Setting up file imports
origins_file = tmp_dir + geoid + '-origins'
destinations_file = tmp_dir + geoid + '-destinations.csv'
output_file = tmp_dir + geoid + '-output'

# Getting the datetime for the nearest Monday
today = datetime.datetime.now()
get_day = lambda date, day: date + datetime.timedelta(days=(day-date.weekday() + 7) % 7)
d = get_day(today, 0)

# Instantiate an OtpsEntryPoint
otp = OtpsEntryPoint.fromArgs(['--graphs', input_dir, '--router', geoid])

# Start timing the code
start_time = time.time()

# Get the default router
router = otp.getRouter(geoid)

# Create a list of jobs if using chunking
jobs = [str(chunk).zfill(len(str(chunks))) for chunk in range(1, chunks + 1)]
i = 0

def create_matrix(chunk):

    # Create a default request for a given departure time
    req = otp.createRequest()
    req.setDateTime(d.year, d.month, d.day, 12, 00, 00)
    req.setMaxTimeSec(max_travel_time)         # set a limit to maximum travel time
    req.setModes(travel_mode)            # define transport mode
    req.setMaxWalkDistance(max_walk_dist)    # set the maximum distance

    # CSV containing the columns GEOID, X and Y.
    origins = otp.loadCSVPopulation(origins_file + '-' + chunk + '.csv', 'Y', 'X')
    destinations = otp.loadCSVPopulation(destinations_file, 'Y', 'X')

    # Create a CSV output
    csv = otp.createCSVOutput()
    csv.setHeader(['origin', 'destination', 'minutes'])

    # Start loop
    for origin in origins:

        # Create a hacky progress bar
        global i
        i += 1
        pg_pct = str(round((float(i) / origin_length) * 100, 2))

        # Progress bar text and return
        pg_str = "Processing GEOID: {} - ORIGIN {}/{} [{}%]    \r".format(
            geoid, str(i), str(origin_length), pg_pct)
        sys.stdout.write(pg_str)
        sys.stdout.flush()

        # Create router for each origin
        req.setOrigin(origin)
        spt = router.plan(req)
        if spt is None: continue

        # Evaluate the SPT for all points
        result = spt.eval(destinations)

        # Add a new row of result in the CSV output
        for r in result:
            csv.addRow([
                origin.getStringData('GEOID'),
                r.getIndividual().getStringData('GEOID'),
                round(r.getTime() / 60.0, 2)
            ])

    # Save the result
    csv.save(output_file + '-' + chunk + '.csv')

# Threading code
while len(jobs) > 0:
    if threading.active_count() < max_threads + 1:
        chunk = jobs.pop()
        thread = threading.Thread(target=create_matrix, args=[chunk])
        thread.start()
    else:
	sleep(0.1)

while threading.active_count() > 1:
    sleep(0.1)

print("\nAll jobs completed!"

# Stop timing the code
print("Elapsed time was {} seconds.".format(str(time.time() - start_time)))
