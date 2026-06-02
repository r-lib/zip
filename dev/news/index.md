# Changelog

## zip (development version)

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
