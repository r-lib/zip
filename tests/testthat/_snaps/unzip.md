# overwrite is FALSE

    Code
      zip::unzip(z$zip, overwrite = FALSE, exdir = tmp)
    Condition
      Error in `zip::unzip()`:
      ! zip error: Not overwriting `test-dir-<random>/dir/<tempfile>` when extracting `<tempdir>/test-file-<random>.zip` in file zip.c:233

