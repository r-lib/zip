# Class for an external zip process

`zip_process()` returns an R6 class that represents a zip process. It is
implemented as a subclass of
[processx::process](http://processx.r-lib.org/reference/process.md).

## Usage

``` r
zip_process()
```

## Value

A `zip_process` R6 class object, a subclass of
[processx::process](http://processx.r-lib.org/reference/process.md).

## Using the `zip_process` class

    zp <- zip_process()$new(zipfile, files, recurse = TRUE,
                             poll_connection = TRUE,
                             stderr = tempfile(), ...)

See [processx::process](http://processx.r-lib.org/reference/process.md)
for the class methods.

Arguments:

- `zipfile`: Path to the zip file to create.

- `files`: List of file to add to the archive. Each specified file or
  directory in is created as a top-level entry in the zip archive.

- `recurse`: Whether to add the contents of directories recursively.

- `include_directories`: Whether to explicitly include directories in
  the archive. Including directories might confuse MS Office when
  reading docx files, so set this to `FALSE` for creating them.

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

## Examples

``` r
dir.create(tmp <- tempfile())
write.table(iris, file = file.path(tmp, "iris.ssv"))
zipfile <- tempfile(fileext = ".zip")
zp <- zip_process()$new(zipfile, tmp)
zp$wait()
zp$get_exit_status()
#> [1] 0
zip_list(zipfile)
#> # A data frame: 2 × 8
#>   filename     compressed_size uncompressed_size timestamp           permissions
#>   <chr>                  <dbl>             <dbl> <dttm>              <octmode>  
#> 1 file194f7df…               0                 0 2026-06-02 10:23:04 755        
#> 2 file194f7df…            1126              4818 2026-06-02 10:23:04 644        
#> # ℹ 3 more variables: crc32 <hexmode>, offset <dbl>, type <chr>
```
