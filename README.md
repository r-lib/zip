
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zip

> Cross-Platform ‘zip’ Compression

[![Linux Build
Status](https://travis-ci.org/r-lib/zip.svg?branch=master)](https://travis-ci.org/r-lib/zip)
[![Windows Build
status](https://ci.appveyor.com/api/projects/status/github/r-lib/zip?svg=true)](https://ci.appveyor.com/project/gaborcsardi/zip)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror
downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Coverage
Status](https://img.shields.io/codecov/c/github/r-lib/zip/master.svg)](https://codecov.io/github/r-lib/zip?branch=master)

## Installation

``` r
install.packages("zip")
```

## Usage

``` r
library(zip)
#> 
#> Attaching package: 'zip'
#> The following object is masked from 'package:utils':
#> 
#>     zip
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
#> sources.zip 282033 FALSE  644 2019-02-21 10:54:12 2019-02-21 10:54:12
#>                           atime uid gid       uname grname
#> sources.zip 2019-02-21 10:53:19 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>          filename compressed_size uncompressed_size           timestamp
#> 1              R/               0                 0 2019-02-21 10:46:08
#> 2  R/assertions.R             125               296 2019-02-21 10:20:08
#> 3       R/utils.R             772              2791 2019-02-19 10:57:56
#> 4         R/zip.R            1890              5700 2019-02-21 10:46:08
#> 5            src/               0                 0 2019-02-21 10:42:10
#> 6      src/init.c             335               762 2019-02-18 21:16:20
#> 7      src/init.o            1470              3600 2019-02-21 10:20:12
#> 8     src/miniz.c           54987            313432 2019-02-20 11:40:22
#> 9     src/miniz.h           18060             66464 2019-02-18 19:56:28
#> 10    src/miniz.o          123757            331616 2019-02-21 10:20:14
#> 11     src/rzip.c            3430             11991 2019-02-21 10:42:08
#> 12     src/rzip.o           10089             22552 2019-02-21 10:42:10
#> 13     src/zip.so           65694            197088 2019-02-21 10:42:10
```

### Uncompressing ZIP files

`zip_unzip()` uncompresses a ZIP archive:

``` r
exdir <- tempfile()
zip_unzip("sources.zip", exdir = exdir)
dir(exdir)
#> [1] "R"   "src"
```

## License

CC0
