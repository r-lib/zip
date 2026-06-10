# Changelog

## zip (development version)

- [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zipr()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zip_append()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zipr_append()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zip_process()`](https://r-lib.github.io/zip/dev/reference/zip_process.md),
  and [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) /
  [`unzip_process()`](https://r-lib.github.io/zip/dev/reference/unzip_process.md)
  now support password-protected archives using WinZIP AES-256, and
  other encryption schemes.

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  now reports an `encryption` column indicating the encryption scheme
  used for each entry.

- [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) is now
  vectorized. If all arguments apart from `zipfile`, `exdir` and
  `password` are the default, then it unprocesses all files
  concurrently, using a thread pool. The size of the thread pool can be
  set with the `zip_threads` option or the `ZIP_THREADS` environment
  variable.

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  and [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
  now work directly on `http://` and `https://` URLs. They use HTTP
  range requests to download only the central directory and the
  requested entries, so listing or extracting a few files from a large
  remote archive no longer downloads the whole file. If the server does
  not support range requests, they fall back to downloading the entire
  archive (with a warning). This requires the curl package.

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  and [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
  now report the Unix permission bits stored in an archive on Windows as
  well. Previously they always reported `700`/`600` on Windows,
  regardless of the permissions recorded in the ZIP file.

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  and [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
  now report `type == "directory"` for directory entries whose Unix mode
  bits lack `S_IFDIR` but that are marked as directories by a trailing
  slash or the DOS directory attribute (e.g. archives created by
  [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md) itself).
  Previously these were reported as `"file"`.

- [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md) and
  [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) now
  show a progress bar when the `cli` package is installed. For
  [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md), progress
  is byte-level, so large single files are tracked smoothly. For
  [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md),
  progress advances once per extracted entry. Progress bars are (for
  now) opt-in via the `ZIP_PROGRESS=true` environment variable or the
  `zip.progress` option
  ([\#48](https://github.com/r-lib/zip/issues/48)).

- [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) now
  returns a data frame (invisibly) with one row per extracted entry,
  containing the same columns as
  [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  (`filename`, `compressed_size`, `uncompressed_size`, `timestamp`,
  `permissions`, `crc32`, `offset`, `type`) plus a `path` column with
  the absolute path to each extracted file on disk
  ([\#35](https://github.com/r-lib/zip/issues/35)).

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  and [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
  now have an `encoding` argument for ZIP files with non-UTF-8,
  non-CP437 filenames (e.g. CP932/Shift-JIS on Japanese Windows). When
  `encoding` is set, filenames without the UTF-8 flag are decoded from
  the specified code page instead of CP437
  ([\#101](https://github.com/r-lib/zip/issues/101)).

- [`zip_append()`](https://r-lib.github.io/zip/dev/reference/zip.md) and
  [`zipr_append()`](https://r-lib.github.io/zip/dev/reference/zip.md)
  now replace existing entries when appending a file whose archive path
  already exists in the zip file, instead of creating duplicate entries
  ([\#111](https://github.com/r-lib/zip/issues/111)).

- [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) and
  [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  now correctly handle ZIP files with non-UTF-8 filenames
  (e.g. filenames encoded in IBM CP437, as created by many Windows
  tools). The filenames are converted to UTF-8 using the CP437 character
  map when the UTF-8 flag is not set in the ZIP entry
  ([\#103](https://github.com/r-lib/zip/issues/103)).

- New `keys` argument to
  [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zipr()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  [`zip_append()`](https://r-lib.github.io/zip/dev/reference/zip.md),
  and
  [`zipr_append()`](https://r-lib.github.io/zip/dev/reference/zip.md).
  It allows specifying custom paths for entries inside the archive,
  independently of their paths on disk
  ([\#50](https://github.com/r-lib/zip/issues/50)).

- Updated embedded miniz to version 3.1.1
  ([\#122](https://github.com/r-lib/zip/issues/122)).

## zip 2.3.3

CRAN release: 2025-05-13

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  now has a `type` column, for the file type.

- [`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) now
  correctly creates symbolic links on Unix
  ([\#127](https://github.com/r-lib/zip/issues/127)).

## zip 2.3.2

CRAN release: 2025-02-01

- [`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
  now returns a `tbl` object, and loads the pillar package, if
  installed, to produce the nicer output for long data frames.

## zip 2.3.1

CRAN release: 2024-01-27

- The zip shared library now hides its symbols (on platforms that
  support this), to avoid name clashes with other libraries
  ([\#98](https://github.com/r-lib/zip/issues/98)).

## zip 2.3.0

CRAN release: 2023-04-17

- zip now handles large zip files on Windows
  ([\#65](https://github.com/r-lib/zip/issues/65),
  [\#75](https://github.com/r-lib/zip/issues/75),
  [\#79](https://github.com/r-lib/zip/issues/79),
  [@weshinsley](https://github.com/weshinsley)).

- zip now behaves better for absolute paths in mirror mode, and when the
  paths contain a `:` character
  ([\#69](https://github.com/r-lib/zip/issues/69),
  [\#70](https://github.com/r-lib/zip/issues/70)).

- [`zip::unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
  now uses the process’s umask value (see `umask(2)`) on Unix if the zip
  file does not contain Unix permissions
  ([\#67](https://github.com/r-lib/zip/issues/67)).

- Fix segmentation fault when zip file can’t be created
  ([\#91](https://github.com/r-lib/zip/issues/91),
  [@zeehio](https://github.com/zeehio))

- Fix delayed evaluation error on zipfile when
  [`zip::zip()`](https://r-lib.github.io/zip/dev/reference/zip.md) is
  used ([\#92](https://github.com/r-lib/zip/issues/92),
  [@zeehio](https://github.com/zeehio))

- New
  [`deflate()`](https://r-lib.github.io/zip/dev/reference/deflate.md)
  and
  [`inflate()`](https://r-lib.github.io/zip/dev/reference/inflate.md)
  functions to compress and uncompress GZIP streams in memory.

## zip 2.2.2

CRAN release: 2022-10-26

- No user visible changes.

## zip 2.2.1

CRAN release: 2022-09-08

- No user visible changes.
