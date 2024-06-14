#!/bin/bash

# prefixes all lines of commands written to stdout with datetime
PS4='\000[$(date)]\011'
export TZ=Europe/London

# set frequency of instance usage in logs to 10 seconds
kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
/usr/bin/dx-dstat 30

set -exo pipefail

main() {
    SECONDS=0
    /usr/bin/time -v dx-download-all-inputs
    duration=$SECONDS

    total=$(du -sh /home/dnanexus/in | cut -f1)

    echo "Downloaded with dx-download-all-inputs --parallel $(find in/ -type f | wc -l) files " \
        "(${total}) in $(($duration / 60))m$(($duration % 60))s"

    rm -rf in/

    sleep 30  # add a gap in the logs to easily see the different parts

    SECONDS=0
    CORES=$(nproc --all)

    # drop the $dnanexus_link from the file IDs in array input
    file_ids=$(grep -Po  "file-[\d\w]+" <<< "${run_tar_data[@]}")

    echo "$file_ids" | xargs -P$(CORES) -n1 -I{} sh -c "dx download --no-progress {}"

    duration=$SECONDS

    total=$(du -sh /home/dnanexus/in | cut -f1)

    echo "Downloaded with xargs in parallel $(find in/ -type f | wc -l) files " \
        "(${total}) in $(($duration / 60))m$(($duration % 60))s"

}

