# overwrite is FALSE

    Code
      zip::unzip(z$zip, overwrite = FALSE, exdir = tmp)
    Condition
      Error in `zip::unzip()`:
      ! Not overwriting `test-dir-<random>/dir/<tempfile>` when extracting `<tempdir>/test-file-<random>.zip` @rzip.c:199 (R_zip_error_handler)

