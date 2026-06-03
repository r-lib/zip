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
  encoding = NULL
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

## Permissions

If the zip archive stores permissions and was created on Unix, the
permissions will be restored.

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
#> # A data frame: 3 × 8
#>   filename    compressed_size uncompressed_size timestamp           permissions
#>   <chr>                 <dbl>             <dbl> <dttm>              <octmode>  
#> 1 mydir/                    0                 0 2026-06-03 09:25:34 755        
#> 2 mydir/file1              15                10 2026-06-03 09:25:34 644        
#> 3 mydir/file2              16                11 2026-06-03 09:25:34 644        
#> # ℹ 3 more variables: crc32 <hexmode>, offset <dbl>, type <chr>

## Extract
tmp2 <- tempfile()
unzip(zipfile, exdir = tmp2)
dir(tmp2, recursive = TRUE)
#> [1] "mydir/file1" "mydir/file2"
```
