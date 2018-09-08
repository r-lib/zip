


# zip

> Cross-Platform 'zip' Compression

[![Linux Build Status](https://travis-ci.org/r-lib/zip.svg?branch=master)](https://travis-ci.org/r-lib/zip)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/r-lib/zip?svg=true)](https://ci.appveyor.com/project/gaborcsardi/zip)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Coverage Status](https://img.shields.io/codecov/c/github/r-lib/zip/master.svg)](https://codecov.io/github/r-lib/zip?branch=master)

## Installation


```r
source("https://install-github.me/jefferis/zip")
```

## Usage


```r
library(ziplist64)
```

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:


```r
utils::zip("sources.zip", dir("src", full.names = TRUE))
zip_list("sources.zip")
```

```
#>            filename compressed_size uncompressed_size           timestamp
#> 1        src/init.c             272               439 2018-09-08 10:22:06
#> 2        src/init.o            1359              3256 2018-09-08 10:30:50
#> 3       src/miniz.c           54348            313433 2018-02-20 18:04:52
#> 4       src/miniz.h           18004             66933 2018-02-20 18:04:52
#> 5       src/miniz.o          121051            310264 2018-09-08 10:30:50
#> 6        src/rzip.c             452              1191 2018-09-08 08:45:04
#> 7        src/rzip.o            2141              5248 2018-09-08 10:30:50
#> 8         src/zip.c            1305              3584 2018-09-08 10:07:52
#> 9         src/zip.h             617              1041 2018-09-08 08:12:34
#> 10        src/zip.o            4143              9028 2018-09-08 10:30:50
#> 11 src/ziplist64.so           45928            110588 2018-09-08 10:30:50
```

### Uncompressing ZIP files

This is currently not supported by the `zip` package, but available from
base R, via `utils::unzip()`.

## License

CC0
