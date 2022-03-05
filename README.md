
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zip

> Cross-Platform ‘zip’ Compression

<!-- badges: start -->

[![R build
status](https://github.com/r-lib/zip/workflows/R-CMD-check/badge.svg)](https://github.com/r-lib/zip/actions)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror
downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Coverage
Status](https://img.shields.io/codecov/c/github/r-lib/zip/main.svg)](https://codecov.io/github/r-lib/zip?branch=main)
<!-- badges: end -->

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
#> sources.zip 604675 FALSE  644 2021-05-30 22:54:38 2021-05-30 22:54:38
#>                           atime uid gid       uname grname
#> sources.zip 2021-05-30 22:53:51 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>                                                     filename compressed_size
#> 1                                                         R/               0
#> 2                                             R/assertions.R             125
#> 3                                                R/process.R            1755
#> 4                                                  R/utils.R             941
#> 5                                                    R/zip.R            3148
#> 6                                                       src/               0
#> 7                                                 src/init.c             335
#> 8                                                 src/init.o            1599
#> 9                                         src/install.libs.R             272
#> 10                                              src/Makevars             199
#> 11                                          src/Makevars.win             273
#> 12                                               src/miniz.c           55180
#> 13                                               src/miniz.h           18113
#> 14                                               src/miniz.o          132730
#> 15                                                src/rzip.c            2123
#> 16                                                src/rzip.o            8003
#> 17                                                src/tools/               0
#> 18                                        src/tools/cmdunzip           51424
#> 19                                      src/tools/cmdunzip.c             590
#> 20                                  src/tools/cmdunzip.dSYM/               0
#> 21                         src/tools/cmdunzip.dSYM/Contents/               0
#> 22               src/tools/cmdunzip.dSYM/Contents/Info.plist             304
#> 23               src/tools/cmdunzip.dSYM/Contents/Resources/               0
#> 24         src/tools/cmdunzip.dSYM/Contents/Resources/DWARF/               0
#> 25 src/tools/cmdunzip.dSYM/Contents/Resources/DWARF/cmdunzip           97049
#> 26                                          src/tools/cmdzip           51879
#> 27                                        src/tools/cmdzip.c            1066
#> 28                                    src/tools/cmdzip.dSYM/               0
#> 29                           src/tools/cmdzip.dSYM/Contents/               0
#> 30                 src/tools/cmdzip.dSYM/Contents/Info.plist             303
#> 31                 src/tools/cmdzip.dSYM/Contents/Resources/               0
#> 32           src/tools/cmdzip.dSYM/Contents/Resources/DWARF/               0
#> 33     src/tools/cmdzip.dSYM/Contents/Resources/DWARF/cmdzip           97654
#> 34                                           src/unixutils.c             724
#> 35                                           src/unixutils.o            4725
#> 36                                            src/winutils.c            1931
#> 37                                                 src/zip.c            2726
#> 38                                                 src/zip.h             808
#> 39                                                 src/zip.o           11779
#> 40                                                src/zip.so           51765
#>    uncompressed_size           timestamp permissions    crc32 offset
#> 1                  0 2021-04-19 20:08:24         755 00000000      0
#> 2                296 2019-02-22 22:11:46         644 82c65ed5     32
#> 3               6479 2020-08-10 15:05:56         644 818cbd3a    217
#> 4               3150 2020-07-10 11:33:36         644 75732ae5   2029
#> 5               9920 2021-04-19 20:08:24         644 385b510f   3025
#> 6                  0 2021-05-30 20:54:36         755 00000000   6226
#> 7                762 2019-02-22 22:11:46         644 d6b21cec   6260
#> 8               3844 2021-02-09 14:27:58         644 91bd3ca8   6651
#> 9                587 2020-07-10 10:20:48         644 4f80df1a   8306
#> 10               525 2020-07-15 13:40:24         644 c8789e48   8642
#> 11               700 2020-08-10 15:05:56         644 373232f9   8899
#> 12            314758 2021-01-30 12:23:14         644 7b72d73e   9234
#> 13             66863 2019-02-24 22:55:36         644 5e7da5e7  64471
#> 14            354268 2021-02-09 14:28:02         644 c2ac4b13  82641
#> 15              6703 2021-04-19 20:08:24         644 e84a5170 215428
#> 16             18996 2021-05-30 20:54:36         644 132b14e7 217607
#> 17                 0 2021-05-30 20:54:36         755 00000000 225666
#> 18            116472 2021-05-30 20:54:36         755 1045b444 225706
#> 19              1343 2020-08-10 15:11:22         644 1a6e34f1 277194
#> 20                 0 2021-02-09 14:27:58         755 00000000 277850
#> 21                 0 2021-02-09 14:27:58         755 00000000 277904
#> 22               637 2021-05-30 20:54:36         644 294928f0 277967
#> 23                 0 2021-02-09 14:27:58         755 00000000 278360
#> 24                 0 2021-02-09 14:27:58         755 00000000 278433
#> 25            281883 2021-05-30 20:54:36         644 28d71d4c 278512
#> 26            116640 2021-05-30 20:54:34         755 dea8616e 375664
#> 27              2909 2020-08-10 15:11:42         644 bfb4d8f3 427605
#> 28                 0 2021-02-09 14:27:52         755 00000000 428735
#> 29                 0 2021-02-09 14:27:52         755 00000000 428787
#> 30               635 2021-05-30 20:54:34         644 c3375fb9 428848
#> 31                 0 2021-02-09 14:27:52         755 00000000 429238
#> 32                 0 2021-02-09 14:27:52         755 00000000 429309
#> 33            283475 2021-05-30 20:54:34         644 1150b348 429386
#> 34              1944 2020-07-15 13:40:24         644 d38da4b6 527139
#> 35             10824 2021-02-09 14:28:04         644 835d78fa 527924
#> 36              6831 2021-02-09 14:58:56         644 3eadc2a2 532710
#> 37             11247 2021-02-09 14:58:56         644 c8051811 534701
#> 38              2349 2021-01-30 12:23:14         644 92f80ead 537482
#> 39             28120 2021-05-30 20:54:36         644 13123666 538345
#> 40            122240 2021-05-30 20:54:36         755 58e052a1 550179
```

### Uncompressing ZIP files

`unzip()` uncompresses a ZIP archive:

``` r
exdir <- tempfile()
unzip("sources.zip", exdir = exdir)
dir(exdir)
#> [1] "R"   "src"
```

### Compressing and uncompressing in background processes

You can use the `zip_process()` and `unzip_process()` functions to
create background zip / unzip processes. These processes were
implemented on top of the `processx::process` class, so they are
pollable.

## License

CC0
