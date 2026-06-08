# backslash is an error

    Code
      zip(tmpzip, tmp, mode = "cherry-pick")
    Condition
      Error in `zip_internal()`:
      ! Cannot add file `zip-test-bs-<random>/real\bad` to archive `<tempdir>/zip-test-bs-<random>.zip`: invalid filename @rzip.c:199 (R_zip_error_handler)

