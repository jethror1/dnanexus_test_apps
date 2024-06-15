
set -exo pipefail

# prefixes all lines of commands written to stdout with datetime
PS4='\000[$(date)]\011'
export TZ=Europe/London
set -exo pipefail

# set frequency of instance usage in logs to 30 seconds
kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
/usr/bin/dx-dstat 30


main() {

    echo "Starting"

    # generate a large amount of lines to the logs in 1000 line bursts
    for i in $(seq 1 20); do
        printf "Starting iteration ${i}\n"
        for j in $(seq 1 1000); do
            printf "${j}\t$(echo $RANDOM | md5sum)\n"
        done
        sleep 60
    done

    echo "Done"

}

