version 1.1

task job_log_test_wdl {
    command <<<

        set -exuo pipefail

        # set frequency of instance usage in logs to 10 seconds
        kill $(ps aux | grep pcp-dstat | head -n1 | awk '{print $2}')
        /usr/bin/dx-dstat 10

        sleep 30

        exit 1
    >>>

    runtime {
        dx_instance_type: "mem1_ssd1_v2_x2"
    }
}
