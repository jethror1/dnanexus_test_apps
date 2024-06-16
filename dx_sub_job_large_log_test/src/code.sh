
set -exo pipefail

# prefixes all lines of commands written to stdout with datetime
PS4='\000[$(date)]\011'
export TZ=Europe/London
set -exo pipefail

# set frequency of instance usage in logs to 30 seconds
kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
/usr/bin/dx-dstat 30


_sub_job() {
    : '''
    sub job to run for 10 minutes to simulate large no. parallel sub jobs with some amount of logging
    '''
    echo "starting"

    # generate a large amount of lines to the logs in 1000 line bursts for ~ 10 minutes
    for i in $(seq 1 10); do
        printf "Starting iteration ${i}\n"
        for j in $(seq 1 1000); do
            printf "${j}\t$(echo $RANDOM | md5sum)\n"
        done
        sleep 60
    done

    echo "done"
}


main() {

    echo "Starting"

    # dump a load of lines to the logs to simulate other apps where
    # there's a large amount before starting sub jobs
    for i in $(seq 1 10); do
        printf "Starting iteration ${i}\n"
        for j in $(seq 1 1000); do
            printf "${j}\t$(echo $RANDOM | md5sum)\n"
        done
    done

    # start up 72 sub jobs
    xargs -n1 -P16 -I{} bash -c \
        "dx-jobutil-new-job _sub_job \
        --instance-type=\"mem1_ssd1_v2_x2\" \
        --name \"sub job {}\"" >> job_ids <<< $(seq 1 72)

    dx wait --from-file job_ids

    echo "Done"

}

