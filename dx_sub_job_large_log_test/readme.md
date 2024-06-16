App to test the disk speed and storage drive type being used in an app environment.

This was run by looping over the outputs from `dx run --instance-type-help` and providing the instance type as input to `--instance-type`. This then generates the full results of sysbench as a file, and a tsv string output containing the instance type, no. CPUS, storage space, storage type, and write speed.

The results strings can then be dumped together and an example is in `instance_summary`.

This was done to investigate the large variability in disk speed impacting run time of jobs when increasing the the `_ssd2` instance types and try to quantify the difference in speeds between instance types of the same no. of CPUs.