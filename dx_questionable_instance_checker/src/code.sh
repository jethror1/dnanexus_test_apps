
set -exo pipefail

main() {
    apt install -y sysbench

    instance=$(jq -r '.instanceType' dnanexus-job.json)
    cpu=$(nproc)

    sysbench --test=fileio --file-test-mode=seqwr run > ${instance}_sysbench_stats.txt

    written=$(cat ${instance}_sysbench_stats.txt | grep "written" | grep -Eo "[0-9]+\.[0-9]+")


    space=$(lsblk | grep -Eo "[0-9]+.*G|[0-9]+.*T" | sort -k 4 | tail -n1 | grep -Eo "[0-9]+\.[0-9][A-Z]")

    sudo lshw -c storage -c disk -short

    type=$(sudo lshw -c storage -c disk -short | tail -n2 | head -n1)
    type=$(echo $type | cut -d' ' -f3-)

    echo $stats
    echo $space
    echo $type

    stats=$(dx upload ${instance}_sysbench_stats.txt --brief)
    dx-jobutil-add-output "summary" $stats

    dx-jobutil-add-output "results" "$instance\t$cpu\t$space\t$type\t$written"
}

