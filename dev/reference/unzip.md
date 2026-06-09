# Uncompress 'zip' Archives

`unzip()` always restores modification times of the extracted files and
directories.

## Usage

``` r
unzip(
  zipfile,
  files = NULL,
  overwrite = TRUE,
  junkpaths = FALSE,
  exdir = ".",
  encoding = NULL,
  password = NULL
)
```

## Arguments

- zipfile:

  Path to the zip file to uncompress.

- files:

  Character vector of files to extract from the archive. Files within
  directories can be specified, but they must use a forward slash as
  path separator, as this is what zip files use internally. If `NULL`,
  all files will be extracted.

- overwrite:

  Whether to overwrite existing files. If `FALSE` and a file already
  exists, then an error is thrown.

- junkpaths:

  Whether to ignore all directory paths when creating files. If `TRUE`,
  all files will be created in `exdir`.

- exdir:

  Directory to uncompress the archive to. If it does not exist, it will
  be created.

- encoding:

  Encoding to use for entry filenames. ZIP files signal UTF-8 filenames
  via a flag in each entry; those are always decoded as UTF-8 regardless
  of `encoding`. For entries without that flag, `encoding` is used;
  `NULL` (the default) falls back to IBM CP437, which is what the ZIP
  specification prescribes for legacy entries. The value is passed to
  [`iconv()`](https://rdrr.io/r/base/iconv.html).

- password:

  Password for decrypting encrypted entries. It can be a string, a raw
  vector, or a function that returns one of these. If `NULL` (the
  default), the `zip_password` option is used, or no password if that is
  also `NULL`. The password is silently ignored for entries that are not
  encrypted.

## Value

A data frame with one row per extracted entry and columns, invisibly:
`filename` (path within the archive), `compressed_size`,
`uncompressed_size`, `timestamp`, `permissions`, `crc32`, `offset`,
`type` (same as in
[`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)),
and `path` (absolute path to the extracted file on disk).

## Permissions

If the zip archive stores permissions and was created on Unix, the
permissions will be restored.

## See also

Other zip/unzip functions:
[`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)

## Examples

``` r
## temporary directory, to avoid messing up the user's workspace.
dir.create(tmp <- tempfile())
dir.create(file.path(tmp, "mydir"))
cat("first file", file = file.path(tmp, "mydir", "file1"))
cat("second file", file = file.path(tmp, "mydir", "file2"))

zipfile <- tempfile(fileext = ".zip")
zip::zip(zipfile, "mydir", root = tmp)

## List contents
zip_list(zipfile)
#> # A data frame: 3 × 9
#>   filename    compressed_size uncompressed_size timestamp           permissions
#>   <chr>                 <dbl>             <dbl> <dttm>              <octmode>  
#> 1 mydir/                    0                 0 2026-06-09 11:03:34 755        
#> 2 mydir/file1              15                10 2026-06-09 11:03:34 644        
#> 3 mydir/file2              16                11 2026-06-09 11:03:34 644        
#> # ℹ 4 more variables: crc32 <hexmode>, offset <dbl>, type <chr>,
#> #   encryption <chr>

## Extract and inspect result
tmp2 <- tempfile()
result <- unzip(zipfile, exdir = tmp2)
result[, c("filename", "path")]
#> # A data frame: 3 × 2
#>   filename    path                                        
#>   <chr>       <chr>                                       
#> 1 mydir/      /tmp/Rtmpm2lP7u/file1aca55685d21/mydir/     
#> 2 mydir/file1 /tmp/Rtmpm2lP7u/file1aca55685d21/mydir/file1
#> 3 mydir/file2 /tmp/Rtmpm2lP7u/file1aca55685d21/mydir/file2
```
