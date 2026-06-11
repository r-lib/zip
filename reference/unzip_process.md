# Class for an external unzip process

`unzip_process()` returns an R6 class that represents an unzip process.
It is implemented as a subclass of
[processx::process](http://processx.r-lib.org/reference/process.md).

## Usage

``` r
unzip_process()
```

## Value

An `unzip_process` R6 class object, a subclass of
[processx::process](http://processx.r-lib.org/reference/process.md), or
a subclass of
[callr::r_process](https://callr.r-lib.org/reference/r_process.html)
when the fallback is active (see the Fallback section below).

## Using the `unzip_process` class

    up <- unzip_process()$new(zipfile, exdir = ".", poll_connection = TRUE,
                               stderr = tempfile(), ...)

See [processx::process](http://processx.r-lib.org/reference/process.md)
for the class methods.

Arguments:

- `zipfile`: Path to the zip file to uncompress.

- `exdir`: Directory to uncompress the archive to. If it does not exist,
  it will be created.

- `poll_connection`: passed to the `initialize` method of
  [processx::process](http://processx.r-lib.org/reference/process.md),
  it allows using
  [`processx::poll()`](http://processx.r-lib.org/reference/poll.md) or
  the `poll_io()` method to poll for the completion of the process.

- `stderr`: passed to the `initialize` method of
  [processx::process](http://processx.r-lib.org/reference/process.md),
  by default the standard error is written to a temporary file. This
  file can be used to diagnose errors if the process failed.

- `...` passed to the `initialize` method of
  [processx::process](http://processx.r-lib.org/reference/process.md).

## Fallback

`unzip_process()` normally runs the bundled `cmdunzip` native executable
via [processx::process](http://processx.r-lib.org/reference/process.md).
If the executable cannot be found or fails its self-test it falls back
to running [`unzip()`](https://r-lib.github.io/zip/reference/unzip.md)
in a background R process via
[callr::r_process](https://callr.r-lib.org/reference/r_process.html).
This may happen when system policies do not allow starting the
`cmdunzip` executable., The fallback class has the same interface but
inherits from
[callr::r_process](https://callr.r-lib.org/reference/r_process.html)
instead of
[processx::process](http://processx.r-lib.org/reference/process.md).

Set the environment variable `R_ZIP_PROCESS_FALLBACK=true` to force the
fallback unconditionally.

## Encoding

The `unzip_process` class does not support the `encoding` argument of
[`unzip()`](https://r-lib.github.io/zip/reference/unzip.md). Non-UTF-8
filenames are decoded using the IBM CP437 fallback. Use
[`unzip()`](https://r-lib.github.io/zip/reference/unzip.md) directly if
you need to handle ZIP files with filenames in other encodings (e.g.
CP932).

## Examples

``` r
ex <- system.file("example.zip", package = "zip")
tmp <- tempfile()
up <- unzip_process()$new(ex, exdir = tmp)
up$wait()
up$get_exit_status()
#> [1] 0
dir(tmp)
#> [1] "example"
```
