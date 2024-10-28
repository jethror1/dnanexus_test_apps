App to test out rewriting dx-download-all-inputs to parallelise across available CPU cores with multiple threads.

> [!IMPORTANT]
> This does not seem to work well like it has for [S3 Upload](https://github.com/eastgenomics/s3_upload) and dxpy.download_dxfile does not play nicely with additional
> `ProcessPoolExecutor` or `ThreadPoolExecutor` (likely due to the internal threading being done [here](https://github.com/dnanexus/dx-toolkit/blob/e788e91d8f6f06592765cfc47b3f815e43a5fbc3/src/python/dxpy/utils/__init__.py#L88)) :sadpanda:
>
> Leaving this here in case I figure out anything to fix the issues later