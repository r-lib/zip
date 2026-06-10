# threaded_unzip errors on a missing zip

    Code
      threaded_unzip("/nonexistent/path/file.zip", exdir)
    Condition
      Error:
      ! Failed to unzip 1 file:
        /nonexistent/path/file.zip: Cannot open zip file `/nonexistent/path/file.zip` for reading

# threaded_unzip reports all failures when multiple zips fail

    Code
      threaded_unzip(c(z$zip, "/bad1.zip", "/bad2.zip"), exdir)
    Condition
      Error:
      ! Failed to unzip 2 files:
        /bad1.zip: Cannot open zip file `/bad1.zip` for reading
        /bad2.zip: Cannot open zip file `/bad2.zip` for reading

# threaded_unzip stops when exdirs length is mismatched

    Code
      threaded_unzip(c(z1$zip, z2$zip), c(d1, d1, d1))
    Condition
      Error in `threaded_unzip()`:
      ! length(exdirs) == 1L || length(exdirs) == length(zipfiles) is not TRUE

# threaded_unzip stops when passwords length is mismatched

    Code
      threaded_unzip(c(z1$zip, z2$zip), exdir, passwords = c("a", "b", "c"))
    Condition
      Error in `threaded_unzip()`:
      ! length(passwords) == 1L || length(passwords) == length(zipfiles) is not TRUE

# get_num_threads errors on invalid zip_threads option

    Code
      get_num_threads()
    Condition
      Error in `get_num_threads()`:
      ! Invalid value for 'zip_threads' option, must be a positive integer.

---

    Code
      get_num_threads()
    Condition
      Error in `get_num_threads()`:
      ! Invalid value for 'zip_threads' option, must be a positive integer.

# get_num_threads errors on invalid ZIP_THREADS env var

    Code
      get_num_threads()
    Condition
      Error in `get_num_threads()`:
      ! Invalid value for ZIP_THREADS environment variable, must be a positive integer.

---

    Code
      get_num_threads()
    Condition
      Error in `get_num_threads()`:
      ! Invalid value for ZIP_THREADS environment variable, must be a positive integer.

