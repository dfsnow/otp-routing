
for GEOID in $(cat cities.csv | cut -d, -f1); do

    find ~/resources/outputs -name "$GEOID*.bz2" | cut -d/ -f6- > /tmp/files_to_copy.txt
    ~/rclone copy -P --files-from /tmp/files_to_copy.txt /home/dfsnow/resources/outputs/ CSDS:"/CSDS Data/OTP Data/"

done
