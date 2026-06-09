# non-existant file

    Code
      withr::with_dir(dirname(tmp), zipr(zipfile, basename(tmp)))
    Condition
      Error in `zip_internal()`:
      ! Some files do not exist

# non readable file

    Code
      withr::with_dir(dirname(tmp), zipr(zipfile, basename(tmp)))
    Condition
      Error in `zip_internal()`:
      ! Cannot add file `<random>` to archive `<tempdir>/<tempfile>.zip` @rzip.c:198 (R_zip_error_handler)

# zip_list on a non-ZIP file includes miniz error

    Code
      zip_list(tmp)
    Condition
      Error in `zip_list()`:
      ! Cannot open zip file `<tempdir>/test-file-<random>.zip`: not a ZIP archive @<location>

# unzip on a non-ZIP file includes miniz error

    Code
      unzip(tmp, exdir = exdir)
    Condition
      Error in `unzip()`:
      ! Cannot open zip file `<tempdir>/test-file-<random>.zip`

# unzip file not in archive includes miniz error

    Code
      unzip(z$zip, files = "no-such-file", exdir = exdir)
    Condition
      Error in `unzip()`:
      ! Cannot find file `no-such-file` in zip archive `<tempdir>/test-file-<random>.zip`: file not found @<location>

