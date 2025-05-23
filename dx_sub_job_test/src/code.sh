
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

    for i in {1..600}; do
        echo "$i"
        sleep 1
    done

    echo "done"
}


main() {

    echo "Starting"

    # start up 72 sub jobs
    xargs -n1 -P16 -I{} bash -c \
        "dx-jobutil-new-job _sub_job \
        --instance-type=\"mem1_ssd1_v2_x2\" \
        --name \"sub job {}\" \
	--extra-args '{\"priority\": \"high\"}'" >> job_ids <<< $(seq 1 72)

    cat job_ids

    dx wait --from-file job_ids

    echo "Done"

}

