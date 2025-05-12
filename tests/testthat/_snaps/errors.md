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
      ! zip error: Cannot add file `<random>` to archive `<tempdir>/<tempfile>.zip` in file zip.c:<line>

