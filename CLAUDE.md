# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

`zip` is an R package providing cross-platform ZIP compression without
requiring external tools. It wraps the bundled
[miniz](https://r-lib.github.io/zip/src/miniz.h) C library via R’s
[`.Call()`](https://rdrr.io/r/base/CallExternal.html) interface.

## Commands

**Install/build for development:**

``` r

# In R:
uncovr::reload()      # load package in-place (fastest for iteration)
uncovr::document()    # regenerate NAMESPACE and man/ from roxygen2 comments
```

**Run tests:**

``` r

uncovr::test()                                           # all tests
uncovr::test(filter = "zip")                             # filter by file name (no "test-" prefix)
```

**Install** (prefer
[`uncovr::reload()`](https://rdrr.io/pkg/uncovr/man/reload.html) for
iteration; only install when needed):

``` r

uncovr::install()
```

**R CMD check:**

``` r

withr::with_envvar(c(NOT_CRAN = "true"), rcmdcheck::rcmdcheck())
```

**Format R code** (uses [air](https://github.com/posit-dev/air)):

``` sh
air format .
```

**Regenerate README.md** (from README.Rmd):

``` sh
make
```

## Architecture

### Layer structure

All public R functions call C via
[`.Call()`](https://rdrr.io/r/base/CallExternal.html). The R layer
handles argument validation and path resolution; the C layer does actual
compression/decompression.

    R functions (R/)
      └── .Call() → C functions (src/rzip.c)
                        └── miniz API (src/miniz.c, src/miniz.h)

The C entry points are registered in
[src/init.c](https://r-lib.github.io/zip/src/init.c): `R_zip_zip`,
`R_zip_unzip`, `R_zip_list`, `R_inflate`, `R_deflate`. They are accessed
in R with the `c_` prefix (e.g. `c_R_zip_zip`) because of the
`.fixes = "c_"` in the `@useDynLib` directive.

### Path resolution (R layer)

`zip_internal()` in [R/zip.R](https://r-lib.github.io/zip/R/zip.R)
delegates path resolution to `get_zip_data()` in
[R/utils.R](https://r-lib.github.io/zip/R/utils.R), which builds a data
frame with columns `key` (path inside the zip), `file` (path on disk),
and `dir` (logical).

Two storage modes are controlled by `keep_path`: - **mirror mode**
(`keep_path = TRUE`): preserves the directory structure relative to
`root` - **cherry-pick mode** (`keep_path = FALSE`): each top-level
entry becomes a root entry in the archive

The `keys` argument (explicit archive paths) bypasses both modes via
`get_zip_data_keys()`.

### Background process variants

[`zip_process()`](https://r-lib.github.io/zip/reference/zip_process.md)
and
[`unzip_process()`](https://r-lib.github.io/zip/reference/unzip_process.md)
in [R/process.R](https://r-lib.github.io/zip/R/process.R) are R6 classes
(subclasses of
[`processx::process`](http://processx.r-lib.org/reference/process.md))
that run standalone command-line executables `cmdzip` and `cmdunzip`.
These are compiled from
[src/tools/cmdzip.c](https://r-lib.github.io/zip/src/tools/cmdzip.c) and
[src/tools/cmdunzip.c](https://r-lib.github.io/zip/src/tools/cmdunzip.c)
by [src/Makevars](https://r-lib.github.io/zip/src/Makevars) alongside
the shared library. `zip_process` serialises its parameters to a binary
file read by `cmdzip`.

### Encoding handling

- On Windows, all file paths go through UTF-8 → UTF-16 conversion
  (`zip__utf8_to_utf16` in
  [src/winutils.c](https://r-lib.github.io/zip/src/winutils.c)) to
  support long paths and non-ASCII names.
- ZIP filenames without the UTF-8 flag (bit 11 of the general purpose
  flag) are treated as IBM CP437 and decoded to UTF-8 via the table in
  [src/zip.c](https://r-lib.github.io/zip/src/zip.c).
- The R helper `enc2c()`
  ([R/utils.R](https://r-lib.github.io/zip/R/utils.R)) converts strings
  to UTF-8 on Windows and native encoding elsewhere before passing them
  to C.
