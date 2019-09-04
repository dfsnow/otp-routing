# Long, ugly one-liner to extract the GEOIDs specified in list_of_geoids from a larger bzipped matrix
bzcat 36061-output-TRACT-CAR.csv.bz2 awk -F',' "$(for x in $(cat list_of_geoids.csv); do printf "\$1 == \"$x\" || "; done | rev | cut -c 4- | rev)"
