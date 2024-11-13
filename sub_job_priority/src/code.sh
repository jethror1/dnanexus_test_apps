#!/bin/bash

# prefixes all lines of commands written to stdout with datetime
PS4='\000[$(date)]\011'
export TZ=Europe/London

# set frequency of instance usage in logs to 10 seconds
kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
/usr/bin/dx-dstat 10

set -exo pipefail

main() {

    echo "starting app"

    for idx in $(seq 1 5); do
        dx-jobutil-new-job _sub_job \
            --instance-type "mem1_ssd1_v2_x2" \
            --extra-args '{"priority": "high"}' \
            --name "sub_job_${idx}" >> job_ids
    done

    dx wait --from-file job_ids

    echo "finished"
}

_sub_job() {
    echo "starting"

    sleep 300

    echo "finished"
}
