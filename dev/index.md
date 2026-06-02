# zip

> Cross-Platform ‘zip’ Compression

## Installation

Stable version:

``` r

install.packages("zip")
```

Development version:

``` r

pak::pak("r-lib/zip")
```

## Usage

``` r

library(zip)
```

### Creating ZIP files

[`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md) creates a
new ZIP archive. (It overwrites the output file if it exists.) Simply
supply all directories and files that you want to include in the
archive.

It makes sense to change to the top-level directory of the files before
archiving them, so that the files are stored using a relative path name.

``` r

zip("sources.zip", c("R", "src"))
file.info("sources.zip")
#>               size isdir mode               mtime               ctime
#> sources.zip 603127 FALSE  644 2025-01-07 10:40:54 2025-01-07 10:40:54
#>                           atime uid gid       uname grname
#> sources.zip 2023-11-03 17:09:37 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

[`zip_append()`](https://r-lib.github.io/zip/dev/reference/zip.md) is
similar to [`zip()`](https://r-lib.github.io/zip/dev/reference/zip.md),
but it appends files to an existing ZIP archive.

### Listing ZIP files

[`zip_list()`](https://r-lib.github.io/zip/dev/reference/zip_list.md)
lists files in a ZIP archive. It returns a data frame:

``` r

zip_list("sources.zip")
#> # A data frame: 49 × 7
#>    filename    compressed_size uncompressed_size timestamp           permissions
#>    <chr>                 <dbl>             <dbl> <dttm>              <octmode>  
#>  1 R/                        0                 0 2025-01-07 09:36:04 755        
#>  2 R/assertio…             151               398 2023-04-17 10:20:40 644        
#>  3 R/compat-v…            3333             13294 2025-01-07 09:36:04 644        
#>  4 R/inflate.R             627              2174 2023-04-17 10:20:40 644        
#>  5 R/process.R            1793              6585 2023-04-17 10:20:40 644        
#>  6 R/utils.R              1184              3757 2025-01-07 09:36:50 644        
#>  7 R/zip-pack…              99               122 2023-11-07 01:18:44 644        
#>  8 R/zip.R                3290             10384 2025-01-07 09:39:50 644        
#>  9 src/                      0                 0 2025-01-07 09:01:34 755        
#> 10 src/init.c              406              1043 2023-11-07 01:18:16 644        
#> # ℹ 39 more rows
#> # ℹ 2 more variables: crc32 <hexmode>, offset <dbl>
```

### Uncompressing ZIP files

[`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
uncompresses a ZIP archive:

``` r

exdir <- tempfile()
unzip("sources.zip", exdir = exdir)
dir(exdir)
#> [1] "R"   "src"
```

### Compressing and uncompressing in background processes

You can use the
[`zip_process()`](https://r-lib.github.io/zip/dev/reference/zip_process.md)
and
[`unzip_process()`](https://r-lib.github.io/zip/dev/reference/unzip_process.md)
functions to create background zip / unzip processes. These processes
were implemented on top of the
[`processx::process`](http://processx.r-lib.org/reference/process.md)
class, so they are pollable.

## License

MIT
