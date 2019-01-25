#!/usr/bin/jython
from org.opentripplanner.scripting.api import OtpsEntryPoint
from time import sleep
import threading
import datetime
import time
import os
import gc

gc.collect()

# Importing the current county and config vars
geoid = os.environ.get('GEOID')
working_dir = os.environ.get('WORKING_DIR')
location_dir = os.environ.get('LOCATION_DIR')

# Setup for threading
chunks = int(os.environ.get('CHUNKS'))
max_threads = int(os.environ.get('MAX_THREADS'))

# Setting up file imports
origins_file = working_dir + location_dir + str(geoid) + '-origins-'
destinations_file = working_dir + location_dir + str(geoid) + '-destinations.csv'
output_file = working_dir + str(geoid) + '-output-'

# Getting the datetime for the nearest Monday
today = datetime.datetime.now()
get_day = lambda date, day: date + datetime.timedelta(days=(day-date.weekday() + 7) % 7)
d = get_day(today, 0)

# Instantiate an OtpsEntryPoint
otp = OtpsEntryPoint.fromArgs(['--graphs', working_dir + 'graphs/', '--router', geoid])

# Start timing the code
start_time = time.time()

# Get the default router
router = otp.getRouter(geoid)

# Create a list of jobs if using chunking
jobs = [str(chunk).zfill(len(str(chunks))) for chunk in range(1, chunks + 1)]

def create_matrix(chunk):

    # Create a default request for a given departure time
    req = otp.createRequest()
    req.setDateTime(d.year, d.month, d.day, 12, 00, 00)
    req.setMaxTimeSec(3600)         # set a limit to maximum travel time
    req.setModes('WALK,TRANSIT')            # define transport mode
    #req.setMaxWalkDistance(2000)    # set the maximum distance

    # CSV containing the columns GEOID, X and Y.
    origins = otp.loadCSVPopulation(origins_file + chunk + '.csv', 'Y', 'X')
    destinations = otp.loadCSVPopulation(destinations_file, 'Y', 'X')

    # Create a CSV output
    csv = otp.createCSVOutput()
    csv.setHeader(['origin', 'destination', 'agg_cost', 'walk_dist'])

    # Start Loop
    for origin in origins:
        print "Now Processing: ", origin.getStringData('GEOID')
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
                round(r.getTime() / 60.0, 2),
                r.getWalkDistance()
            ])

    # Save the result
    csv.save(output_file + chunk + '.csv')

# Threading code
# https://github.com/rafapereirabr/otp-travel-time-matrix/blob/master/python_script_loopHM_parallel.py
while len(jobs) > 0:
    if threading.active_count() < max_threads + 1:
        chunk = jobs.pop()
        thread = threading.Thread(target=create_matrix, args=[chunk])
        thread.start()
    else:
	sleep(0.1)

while threading.active_count() > 1:
    sleep(0.1)

print 'All jobs completed!'

# Stop timing the code
print("Elapsed time was %g seconds." % (time.time() - start_time))
