
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
#>               size isdir mode               mtime               ctime
#> sources.zip 281336 FALSE  644 2019-02-22 21:36:30 2019-02-22 21:36:30
#>                           atime uid gid       uname grname
#> sources.zip 2019-02-22 21:36:30 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>              filename compressed_size uncompressed_size
#> 1                  R/               0                 0
#> 2      R/assertions.R             125               296
#> 3         R/process.R             626              1377
#> 4           R/utils.R             905              3047
#> 5             R/zip.R            2156              6686
#> 6                src/               0                 0
#> 7          src/init.c             335               762
#> 8          src/init.o             557              1376
#> 9  src/install.libs.R             259               540
#> 10       src/Makevars             155               271
#> 11   src/Makevars.win             156               283
#> 12        src/miniz.c           55232            314589
#> 13        src/miniz.h           18113             66863
#> 14        src/miniz.o           60555            174988
#> 15         src/rzip.c            2268              7071
#> 16         src/rzip.o            2734              6436
#> 17         src/tools/               0                 0
#> 18    src/tools/unzip           63554            176576
#> 19  src/tools/unzip.c             214               323
#> 20          src/zip.c            2769              9110
#> 21          src/zip.h             406               872
#> 22          src/zip.o            3182              7772
#> 23         src/zip.so           64455            182064
#>              timestamp permissions
#> 1  2019-02-22 19:01:34         755
#> 2  2019-02-21 10:20:08         644
#> 3  2019-02-22 19:01:34         644
#> 4  2019-02-22 17:58:34         644
#> 5  2019-02-22 17:17:02         644
#> 6  2019-02-22 20:29:54         755
#> 7  2019-02-18 21:16:20         644
#> 8  2019-02-22 20:29:54         644
#> 9  2019-02-22 17:34:26         644
#> 10 2019-02-22 20:29:52         644
#> 11 2019-02-22 18:33:50         644
#> 12 2019-02-22 12:27:14         755
#> 13 2019-02-22 10:45:42         644
#> 14 2019-02-22 20:29:54         644
#> 15 2019-02-22 17:22:00         644
#> 16 2019-02-22 20:29:54         644
#> 17 2019-02-22 20:29:54         755
#> 18 2019-02-22 20:29:54         755
#> 19 2019-02-22 17:27:56         644
#> 20 2019-02-22 20:17:54         644
#> 21 2019-02-22 17:49:04         644
#> 22 2019-02-22 20:29:54         644
#> 23 2019-02-22 20:29:54         755
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
