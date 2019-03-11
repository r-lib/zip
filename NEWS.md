
# 2.0.1

* `zip()` and `zip_append()` are now soft-deprecated, please use
  `zipr()` and `zipr_append()` instead.

# 2.0.0

* New `zipr()` and `zipr_append()`, they always store relative file names
  in the archive.

* New `unzip()` function for uncompressing zip archives.

* New `zip_process()` and `unzip_process()` functions to create or
  uncompress an archive in a background process.

* `zip()`, `zipr()`, `zip_append()` and `zipr_append()` all include
  directories in the archives, empty ones as well.

* `zip()`, `zipr()`, `zip_append()` and `zipr_append()` all add time stamps
  to the archive and `zip_list()` returns then in the `timestamp` column.

* `zip()`, `zipr()`, `zip_append()` and `zipr_append()` all add file
  and directory permissions to the archive on Unix systems, and
  `zip_list()` returns them in the `permissions` column.

* `zip_list()` now correctly reports the size of large files in the archive.

* Use miniz 2.0.8 internally.

# 1.0.0

First public release.
