
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
#>              size isdir mode               mtime               ctime
#> sources.zip 87695 FALSE  644 2019-02-23 20:05:10 2019-02-23 20:05:10
#>                           atime uid gid       uname grname
#> sources.zip 2019-02-23 20:05:10 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>                filename compressed_size uncompressed_size
#> 1                    R/               0                 0
#> 2        R/assertions.R             125               296
#> 3           R/process.R            1227              4121
#> 4             R/utils.R             905              3047
#> 5               R/zip.R            2194              6763
#> 6                  src/               0                 0
#> 7            src/init.c             335               762
#> 8    src/install.libs.R             271               576
#> 9          src/Makevars             185               465
#> 10     src/Makevars.win             188               491
#> 11          src/miniz.c           55232            314589
#> 12          src/miniz.h           18113             66863
#> 13           src/rzip.c            2092              6344
#> 14           src/tools/               0                 0
#> 15 src/tools/cmdunzip.c             214               323
#> 16   src/tools/cmdzip.c             909              2599
#> 17            src/zip.c            3169             11295
#> 18            src/zip.h             504              1211
#>              timestamp permissions
#> 1  2019-02-23 20:00:50         755
#> 2  2019-02-22 22:11:46         644
#> 3  2019-02-23 20:00:50         644
#> 4  2019-02-22 22:27:58         644
#> 5  2019-02-23 17:30:12         644
#> 6  2019-02-23 20:05:04         755
#> 7  2019-02-22 22:11:46         644
#> 8  2019-02-23 20:04:12         644
#> 9  2019-02-23 20:03:28         644
#> 10 2019-02-23 20:03:04         644
#> 11 2019-02-23 01:38:12         755
#> 12 2019-02-22 22:11:46         644
#> 13 2019-02-23 10:23:00         644
#> 14 2019-02-23 20:05:04         755
#> 15 2019-02-22 22:27:58         644
#> 16 2019-02-23 16:41:06         644
#> 17 2019-02-23 16:33:22         644
#> 18 2019-02-23 10:40:12         644
```

### Uncompressing ZIP files

`unzip()` uncompresses a ZIP archive:

``` r
exdir <- tempfile()
unzip("sources.zip", exdir = exdir)
dir(exdir)
#> [1] "R"   "src"
```

## License

CC0
