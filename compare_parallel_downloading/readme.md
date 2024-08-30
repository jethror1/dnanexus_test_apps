Test of comparing downloading and uploading using the built in methods vs in parallel with xargs

### Downloading
The built in method looks to be bound to a single core since `concurrent.futures.ThreadPoolExecutor` is being used here: https://github.com/dnanexus/dx-toolkit/blob/6eeb3293bace8c944460fd6aad010b1ad1a6c621/src/python/dxpy/bindings/download_all_inputs.py#L62

Since downloading a file is IO intensive, using multiple threads on a single core seems inefficient and (assumedly) would not give as much of an increase in speed vs using multiple cores (i.e. in Python with `concurrent.futures.ProcessPoolExecutor` to get round the GIL).

There is some attempt to calculate the max no. of download threads by available memory and CPU cores here up to max 8 threads (https://github.com/dnanexus/dx-toolkit/blob/6eeb3293bace8c944460fd6aad010b1ad1a6c621/src/python/dxpy/bindings/download_all_inputs.py#L62)

This is suggesting at least 1.2GB of memory per download thread, but since all the `mem1` instances have a ~2x ratio of memory:cores this shouldn't be an issue if we stick to opening one download per CPU core available with xargs / GNU parallel.

Rough results of running this app with a few different instance types using ~200GB input data split between 125 files from here:
```
$ echo $(( $(dx find data --path project-FpVG0G84X7kzq58g19vF1YJQ:/240122_A01295_0303_AHTNWYDRX3/runs/ \
    --name "*tar*" --json --verbose \
    | jq -r '.[].describe.size' | paste -sd+ | bc) / 1024 / 1024 / 1024)) GB
194 GB
```

## Uploading

Same as for downloading, uploading uses  and is hardcoded to 8 threads here: https://github.com/dnanexus/dx-toolkit/blob/6eeb3293bace8c944460fd6aad010b1ad1a6c621/src/python/scripts/dx-upload-all-outputs#L336

Recorded total time and approximate peak usage of CPU, RAM and download speed

**mem1_ssd1_v2_x8**


* TODO: run this across some instances and generate some comparisons

**mem1_ssd1_v2_x36**

`dx-download-all-inputs --parallel`
- max CPU: 5%
- max download speed:

`xargs`
- max CPU:
- max download speed:


### Uploading



**mem1_ssd1_v2_x8**




**mem1_ssd1_v2_x36**

