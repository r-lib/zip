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
[processx::process](http://processx.r-lib.org/reference/process.md).

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

## Encoding

The `unzip_process` class does not support the `encoding` argument of
[`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md).
Non-UTF-8 filenames are decoded using the IBM CP437 fallback. Use
[`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md) directly
if you need to handle ZIP files with filenames in other encodings (e.g.
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
