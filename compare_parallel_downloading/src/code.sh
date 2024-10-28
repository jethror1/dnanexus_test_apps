#!/bin/bash

# prefixes all lines of commands written to stdout with datetime
PS4='\000[$(date)]\011'
export TZ=Europe/London

# set frequency of instance usage in logs to 15 seconds
kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
/usr/bin/dx-dstat 15

set -exo pipefail

_dx_built_ins() {
    : '''
    Test using built in parallel implementation of dx-download-all-inputs and dx-upload-all-outputs
    '''
    echo "Downloading with dx-download-all-inputs"

    SECONDS=0
    /usr/bin/time -v dx-download-all-inputs --parallel 1> /dev/null
    duration=$SECONDS

    total_size=$(du -sh /home/dnanexus/in/ | cut -f1)
    total_files=$(find in/ -type f | wc -l)
    elapsed="$(($duration / 60))m$(($duration % 60))s"

    echo "Downloaded with dx-download-all-inputs --parallel ${total_files} files " \
        "(${total_size}) in ${elapsed}"

    printf "dx-download-all-inputs --parallel\t${elapsed}\t${total_files}\t${total_size}\n" \
        >> "${DX_JOB_ID}_summary.tsv"

    # move downloaded files to be able to upload
    find in/ -type f -print0 | xargs -0 -I {} mv {} ~/out/files

    echo "Uploading with dx-upload-all-outputs"
    SECONDS=0
    /usr/bin/time -v dx-upload-all-outputs --parallel 1> /dev/null
    duration=$SECONDS
    elapsed="$(($duration / 60))m$(($duration % 60))s"

    echo "Uploaded with dx-upload-all-outputs --parallel ${total_files} files " \
        "(${total_size}) in ${elapsed}"

    printf "dx-upload-all-outputs\t${elapsed}\t${total_files}\t${total_size}\n" \
        >> "${DX_JOB_ID}_summary.tsv"

    rm -rf out/*

    # clear output spec to not retain files in project on app closing
    echo "{}" > job_output.json
}


_parallel_download_upload () {
    : '''
    Test of calling upload / download in parallel using xargs, with one process
    per CPU core available
    '''
    CORES=$(nproc --all)

    echo "Downloading files in parallel with ${CORES} operations"

    # # drop the $dnanexus_link from the file IDs in array input
    file_ids=$(grep -Po  "file-[\d\w]+" <<< "${files[@]}")

    SECONDS=0
    echo "$file_ids" | xargs -P${CORES} -n1 -I{} sh -c "dx download --no-progress {} -o in/"
    duration=$SECONDS

    total_size=$(du -sh /home/dnanexus/in/ | cut -f1)
    total_files=$(find in/ -type f | wc -l)
    elapsed="$(($duration / 60))m$(($duration % 60))s"

    echo "Downloaded with ${CORES} processes in parallel ${total_files} files " \
        "(${total_size}) in ${elapsed}"

    printf "xargs ${CORES} parallel download processess\t${elapsed}\t${total_files}\t${total_size}\n" \
        >> "${DX_JOB_ID}_summary.tsv"

    # upload in parallel using helper function to allow upload and associating to output spec
    # as we have in a few apps (e.g. https://github.com/eastgenomics/eggd_tso500/blob/master/src/code.sh#L328)
    SECONDS=0
    export -f _upload_single_file  # required to be accessible to xargs sub shell
    find in/ -type f | xargs -P ${CORES} -n1 -I{} bash -c "_upload_single_file {} files true"

    duration=$SECONDS
    elapsed="$(($duration / 60))m$(($duration % 60))s"

    echo "Uploaded with ${CORES} processes in parallel ${total_files} files " \
        "(${total_size}) in ${elapsed}"

    printf "xargs ${CORES} parallel upload processess\t${elapsed}\t${total_files}\t${total_size}\n" \
        >> "${DX_JOB_ID}_summary.tsv"

    # clear output spec to not retain files in project on app closing
    echo "{}" > job_output.json
}


_upload_single_file() {
  : '''
  Uploads single file with dx upload and associates uploaded
  file ID to specified output field

  Arguments
  ---------
    1 : str
        path and file to upload
    2 : str
        app output field to link the uploaded file to
    3 : bool
        (optional) controls if to link output file to job output spec
  '''
  local file=$1
  local field=$2
  local link=$3

  local remote_path=$(sed s'/\/home\/dnanexus\/out\///' <<< "$file")

  file_id=$(dx upload "$file" --path "$remote_path" --parents --brief)

  if [[ "$link" == true ]]; then
    dx-jobutil-add-output "$field" "$file_id" --array
  fi
}

main() {
    mkdir -p in
    mkdir -p out/files

    # summary file for comparison
    printf "method\ttime\ttotal files\ttotal size\n" > "${DX_JOB_ID}_summary.tsv"

    _dx_built_ins
    _parallel_download_upload

    file_id=$(dx upload --brief "${DX_JOB_ID}_summary.tsv")
    dx-jobutil-add-output "summary" "$file_id"

    echo "Done"
}

