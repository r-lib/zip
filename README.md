
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
#> sources.zip 403625 FALSE  644 2019-02-23 01:10:39 2019-02-23 01:10:39
#>                           atime uid gid       uname grname
#> sources.zip 2019-02-23 01:10:27 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>                                               filename compressed_size
#> 1                                                   R/               0
#> 2                                       R/assertions.R             125
#> 3                                          R/process.R             626
#> 4                                            R/utils.R             905
#> 5                                              R/zip.R            2196
#> 6                                                 src/               0
#> 7                                           src/init.c             335
#> 8                                           src/init.o            1459
#> 9                                   src/install.libs.R             259
#> 10                                        src/Makevars             155
#> 11                                    src/Makevars.win             156
#> 12                                         src/miniz.c           55232
#> 13                                         src/miniz.h           18113
#> 14                                         src/miniz.o          118292
#> 15                                          src/rzip.c            2268
#> 16                                          src/rzip.o            7035
#> 17                                          src/tools/               0
#> 18                                     src/tools/unzip           48730
#> 19                                   src/tools/unzip.c             214
#> 20                               src/tools/unzip.dSYM/               0
#> 21                      src/tools/unzip.dSYM/Contents/               0
#> 22            src/tools/unzip.dSYM/Contents/Info.plist             302
#> 23            src/tools/unzip.dSYM/Contents/Resources/               0
#> 24      src/tools/unzip.dSYM/Contents/Resources/DWARF/               0
#> 25 src/tools/unzip.dSYM/Contents/Resources/DWARF/unzip           81955
#> 26                                           src/zip.c            2769
#> 27                                           src/zip.h             406
#> 28                                           src/zip.o            9508
#> 29                                          src/zip.so           49061
#>    uncompressed_size           timestamp permissions
#> 1                  0 2019-02-23 01:08:56         755
#> 2                296 2019-02-22 22:11:46         644
#> 3               1377 2019-02-23 01:08:26         644
#> 4               3047 2019-02-22 22:27:58         644
#> 5               6817 2019-02-23 01:08:56         644
#> 6                  0 2019-02-23 01:03:18         755
#> 7                762 2019-02-22 22:11:46         644
#> 8               3600 2019-02-23 01:03:16         644
#> 9                540 2019-02-22 22:27:58         644
#> 10               271 2019-02-22 22:27:58         644
#> 11               283 2019-02-22 22:27:58         644
#> 12            314589 2019-02-22 22:11:46         755
#> 13             66863 2019-02-22 22:11:46         644
#> 14            300556 2019-02-23 01:03:18         644
#> 15              7071 2019-02-22 22:27:58         644
#> 16             16596 2019-02-23 01:03:18         644
#> 17                 0 2019-02-23 01:03:16         755
#> 18            111952 2019-02-23 01:03:16         755
#> 19               323 2019-02-22 22:27:58         644
#> 20                 0 2019-02-23 01:03:16         755
#> 21                 0 2019-02-23 01:03:16         755
#> 22               634 2019-02-23 01:03:16         644
#> 23                 0 2019-02-23 01:03:16         755
#> 24                 0 2019-02-23 01:03:16         755
#> 25            226179 2019-02-23 01:03:16         644
#> 26              9110 2019-02-22 22:27:58         644
#> 27               872 2019-02-22 22:27:58         644
#> 28             21952 2019-02-23 01:03:18         644
#> 29            117848 2019-02-23 01:03:18         755
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
