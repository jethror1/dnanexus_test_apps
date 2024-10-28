import argparse
from concurrent.futures import (
    ProcessPoolExecutor,
    ThreadPoolExecutor,
    as_completed,
)
import os

import dxpy
from dxpy.utils import file_load_utils


def download_single_file(file_details, download_dir, project=None):
    """
    Downloads single file to given local diretory.

    Adapted from: https://github.com/dnanexus/dx-toolkit/blob/e788e91d8f6f06592765cfc47b3f815e43a5fbc3/src/python/dxpy/bindings/download_all_inputs.py#L44

    Parameters
    ----------
    file_details : dict
        mapping of file details

    """
    file_id = file_details["src_file_id"]
    out_file = os.path.join(download_dir, file_details["trg_fname"])

    print(f"Downloading {file_id} to {out_file}")

    # dxpy.bindings.dxfile_functions.download_dxfile(
    #     dxid=file_id,
    #     filename=out_file,
    # )


def _submit_to_pool(pool, func, item_input, items, **kwargs):
    """
    Submits one call to `func` in `pool` (either ThreadPoolExecutor or
    ProcessPoolExecutor) for each item in `items`. All additional
    arguments defined in `kwargs` are passed to the given function.

    This has been abstracted from both multi_thread_upload and
    multi_core_upload to allow for unit testing of the called function
    raising exceptions that are caught and handled.

    Parameters
    ----------
    pool : ThreadPoolExecutor | ProcessPoolExecutor
        concurrent.futures executor to submit calls to
    func : callable
        function to call on submitting
    item_input : str
        function input field to submit each items of `items` to
    items : iterable
        iterable of object to submit

    Returns
    -------
    dict
        mapping of concurrent.futures.Future objects to the original
        `item` submitted for that future
    """
    return {
        pool.submit(
            func,
            **{**{item_input: item}, **kwargs},
        ): item
        for item in items
    }


def multi_thread_download(files, download_dir, threads):
    """
    Downloads the given set of `files` on a single CPU core using
    maximum of n threads.

    Parameters
    ----------
    files : list
        list of files to download
    download_dir : str
        path to parent directory to download to (i.e /home/dnanexus)
    threads : int
        n number of threads to use for ThreadPoolExecutor

    """
    print(
        f"Downloading {len(files)} files to {download_dir} using"
        f" {threads} threads"
    )

    with ThreadPoolExecutor(max_workers=threads) as executor:
        concurrent_jobs = _submit_to_pool(
            pool=executor,
            func=download_single_file,
            item_input="file_details",
            items=files,
            download_dir=download_dir,
        )

        for future in as_completed(concurrent_jobs):
            # access returned output as each is returned in any order
            # to ensure the file downloaded successfully
            try:
                future.result()
            except Exception as exc:
                print(f"Error in downloading {concurrent_jobs[future]}")
                raise exc


def multi_core_download(files, download_dir, cores, threads):
    """
    Call the multi_thread_download function on `files` split across n
    logical CPU cores with n threads per core

    Parameters
    ----------
    files : list
        list of details for each file to download, comes from
        file_load_utils.get_job_input_filenames
    download_dir : str
        path to parent directory to download to (i.e /home/dnanexus)
    cores : int
        maximum number of logical CPU cores to split uploading across
    threads : int
        maximum number of threaded process to open per core

    Returns
    -------
    dict
        mapping of local file to ETag ID of uploaded file
    list
        list of any files that failed to upload
    """
    print(
        f"Downloading {len(files)} files to {download_dir} using {cores} cores"
    )

    # split list of files to download into equal chunks by how many cores
    # we are using
    files = [files[i : i + cores] for i in range(0, len(files), cores)]

    with ProcessPoolExecutor(max_workers=cores) as executor:
        concurrent_jobs = _submit_to_pool(
            pool=executor,
            func=multi_thread_download,
            item_input="files",
            items=files,
            threads=threads,
            download_dir=download_dir,
        )

        for future in as_completed(concurrent_jobs):
            # access returned output as each is returned in any order
            try:
                future.result()
            except Exception as exc:
                # catch any other errors that might get raised
                print(
                    "Error in downloading one or more files from:"
                    f" {concurrent_jobs[future]}"
                )
                raise exc


def _create_dirs(idir, dirs):
    """
    Create a set of directories, so we could store the input files.
    For example, seq1 could be stored under:
        /in/seq1/NC_001122.fasta

    TODO: this call could fail, we need to report a reasonable error code

    Note that we create a directory for every file array, even if
    it has zero inputs.

    Taken from: https://github.com/dnanexus/dx-toolkit/blob/e788e91d8f6f06592765cfc47b3f815e43a5fbc3/src/python/dxpy/bindings/download_all_inputs.py#L27C1-L42C58
    """
    # create the <idir> itself
    file_load_utils.ensure_dir(idir)
    # create each subdir
    for d in dirs:
        file_load_utils.ensure_dir(os.path.join(idir, d))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--cores",
        type=int,
        default=os.cpu_count(),
        help=(
            "Total CPU cores to split downloading across, defaults to maximum"
            " available"
        ),
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=4,
        help="Total no. of threads to open with each CPU core",
    )

    return parser.parse_args()


def main():
    args = parse_args()

    job_input_file = file_load_utils.get_input_json_file()
    dirs, inputs, _ = file_load_utils.get_job_input_filenames(job_input_file)

    _create_dirs("/home/dnanexus", dirs)

    # flatten to a single list and remove the 'handler' item return from
    # get_job_input_filenames as this is not picklable and not needed
    file_records = [x for y in inputs.values() for x in y]
    file_records = [
        {"trg_fname": x["trg_fname"], "src_file_id": x["src_file_id"]}
        for x in file_records
    ]

    print(f"Found {len(file_records)} files to download")
    print(file_records)

    # TODO - figure out at what point it is beneficial to split across
    # CPU cores and what a sensible default of threads to use (for only
    # a few files it will likely be faster to stick to a single core
    # with multiple threads due to the overhead of opening a ProcessPool)
    multi_core_download(
        files=file_records,
        download_dir="/home/dnanexus",
        cores=args.cores,
        threads=args.threads,
    )


if __name__ == "__main__":
    main()
