
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zip

> Cross-Platform ‘zip’ Compression

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-lib/zip/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/zip/actions/workflows/R-CMD-check.yaml)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror
downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Codecov test
coverage](https://codecov.io/gh/r-lib/zip/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-lib/zip?branch=main)
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
#>              size isdir mode               mtime               ctime
#> sources.zip 92565 FALSE  644 2022-10-24 16:41:03 2022-10-24 16:41:03
#>                           atime uid gid       uname grname
#> sources.zip 2022-09-08 11:17:08 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an
existing ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:

``` r
zip_list("sources.zip")
#>                filename compressed_size uncompressed_size           timestamp
#> 1                    R/               0                 0 2022-09-08 09:14:06
#> 2        R/assertions.R             125               296 2022-03-04 14:05:04
#> 3           R/process.R            1755              6479 2022-03-04 14:05:04
#> 4             R/utils.R             941              3150 2022-03-04 14:05:04
#> 5               R/zip.R            3127              9881 2022-09-08 09:14:06
#> 6                  src/               0                 0 2022-10-24 14:36:52
#> 7            src/init.c             335               762 2022-03-04 14:05:04
#> 8    src/install.libs.R             272               587 2022-03-04 14:05:04
#> 9          src/Makevars             199               525 2022-03-04 14:05:04
#> 10     src/Makevars.win             273               700 2022-03-04 14:05:04
#> 11          src/miniz.c           55181            314766 2022-10-24 14:36:52
#> 12          src/miniz.h           18115             66871 2022-10-24 14:36:52
#> 13           src/rzip.c            2123              6703 2022-03-04 14:05:04
#> 14           src/tools/               0                 0 2022-09-08 09:33:24
#> 15 src/tools/cmdunzip.c             590              1343 2022-03-04 14:05:04
#> 16   src/tools/cmdzip.c            1066              2909 2022-03-04 14:05:04
#> 17      src/unixutils.c             724              1944 2022-03-04 14:05:04
#> 18       src/winutils.c            1931              6831 2022-03-04 14:05:04
#> 19            src/zip.c            2726             11247 2022-03-04 14:05:04
#> 20            src/zip.h             808              2349 2022-03-04 14:05:04
#>    permissions    crc32 offset
#> 1          755 00000000      0
#> 2          644 82c65ed5     32
#> 3          644 818cbd3a    217
#> 4          644 75732ae5   2029
#> 5          644 e00eb685   3025
#> 6          755 00000000   6205
#> 7          644 d6b21cec   6239
#> 8          644 4f80df1a   6630
#> 9          644 c8789e48   6966
#> 10         644 373232f9   7223
#> 11         644 dcd5aaca   7558
#> 12         644 6c5a6c1e  62796
#> 13         644 e84a5170  80968
#> 14         755 00000000  83147
#> 15         644 1a6e34f1  83187
#> 16         644 bfb4d8f3  83843
#> 17         644 d38da4b6  84973
#> 18         644 3eadc2a2  85758
#> 19         644 c8051811  87749
#> 20         644 92f80ead  90530
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
