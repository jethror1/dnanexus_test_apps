Test of comparing downloading using `dx download` in parallel with xargs vs `dx-download-all-inputs --parallel`.

The built in method looks to be bound to a single core since `concurrent.futures.ThreadPoolExecutor` is being used here: https://github.com/dnanexus/dx-toolkit/blob/6eeb3293bace8c944460fd6aad010b1ad1a6c621/src/python/dxpy/bindings/download_all_inputs.py#L62

Since downloading a file is IO intensive, using multiple threads on a single core seems inefficient and (assumedly) would not give much of an increase in speed vs using multiple cores (i.e. with `concurrent.futures.ProcessPoolExecutor`).

There is some attempt to calculate the max no. of download threads by available memory and CPU cores here up to max 8 threads (https://github.com/dnanexus/dx-toolkit/blob/6eeb3293bace8c944460fd6aad010b1ad1a6c621/src/python/dxpy/bindings/download_all_inputs.py#L62)

This is suggesting at least 1.2GB of memory per download thread, but since all the `mem1` instances have a ~2x ratio of memory:cores this shouldn't be an issue if we stick to opening one download per CPU core available with xargs.

Results of running this app with a few different instance types