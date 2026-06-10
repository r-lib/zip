
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zip

> Cross-Platform ‘zip’ Compression

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-lib/zip/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/zip/actions/workflows/R-CMD-check.yaml)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror
downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Codecov test
coverage](https://codecov.io/gh/r-lib/zip/graph/badge.svg)](https://app.codecov.io/gh/r-lib/zip)
<!-- badges: end -->

## Installation

Stable version:

``` r
install.packages("zip")
```

Development version:

``` r
pak::pak("r-lib/zip")
```

## Optional dependencies

- For progress bars (see below), the [cli](https://cli.r-lib.org)
  package is needed.
- Background processes, i.e. `zip_process()` and `unzip_process()`, need
  the [processx](https://processx.r-lib.org) package.

## Usage

``` r
library(zip)
```

### Creating ZIP files

`zip()` creates a new ZIP archive. (It overwrites the output file if it
exists.) Simply supply all directories and files that you want to
include in the archive.

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

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

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

`unzip()` uncompresses a ZIP archive:

``` r
exdir <- tempfile()
unzip("sources.zip", exdir = exdir)
dir(exdir)
#> [1] "R"   "src"
```

### Password-protected archives

Pass a `password` argument to encrypt entries with WinZip AES-256 (the
default), which is supported by 7-Zip, WinZip, and macOS Archive
Utility:

``` r
zip("secret.zip", "R", password = "hunter2")
zip_list("secret.zip")
#> # A data frame: 9 × 9
#>   filename     compressed_size uncompressed_size timestamp           permissions
#>   <chr>                  <dbl>             <dbl> <dttm>              <octmode>  
#> 1 R/                         0                 0 2026-06-09 10:32:24 755        
#> 2 R/assertion…             178               388 2026-06-08 09:00:44 644        
#> 3 R/compat-vc…            3415             14344 2026-06-08 09:00:44 644        
#> 4 R/http.R                4893             16515 2026-06-08 12:10:24 644        
#> 5 R/inflate.R              769              2390 2026-06-08 12:10:24 644        
#> 6 R/process.R             2140              7474 2026-06-09 10:42:48 644        
#> 7 R/utils.R               2249              7483 2026-06-09 10:27:50 644        
#> 8 R/zip-packa…             127               122 2026-06-08 09:00:44 644        
#> 9 R/zip.R                 5218             16564 2026-06-09 10:32:24 644        
#> # ℹ 4 more variables: crc32 <hexmode>, offset <dbl>, type <chr>,
#> #   encryption <chr>
unzip("secret.zip", exdir = tempfile(), password = "hunter2")
```

### Compressing and uncompressing in background processes

You can use the `zip_process()` and `unzip_process()` functions to
create background zip / unzip processes. These processes were
implemented on top of the `processx::process` class, so they are
pollable.

### Progress bars

`zip()` and `unzip()` (and co.) support progress bars if the `cli`
package is installed. This is disabled by default (for now), but can be
enabled by setting the `zip_progress` option or the `ZIP_PROGRESS`
environment variable to `TRUE`.

### Configuration

#### Options

- `zip_password`: The default password for ZIP encryption and
  decryption. Can be set to a string, a raw vector, or a function
  returning one.
- `zip_progress`: If set to `TRUE`, progress bars are enabled. Takes
  precedence over the `ZIP_PROGRESS` environment variable.

#### Environment variables

- `R_ZIP_PROCESS_FALLBACK`: If set to `TRUE`, `unzip_process()`
  functions will fall back to using an R subprocess, without trying to
  use the cmdunzip executable embedded into the package. This is useful
  when `cmdunzip.exe` is blocked by system policies on Windows.
- `ZIP_PROGRESS`: If set to `TRUE`, progress bars are enabled. The
  `zip_progress` option takes precedence over this environment variable.

## License

MIT
