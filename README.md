


# zip

> Cross-Platform 'zip' Compression

[![Linux Build Status](https://travis-ci.org/gaborcsardi/zip.svg?branch=master)](https://travis-ci.org/gaborcsardi/zip)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/gaborcsardi/zip?svg=true)](https://ci.appveyor.com/project/gaborcsardi/zip)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Coverage Status](https://img.shields.io/codecov/c/github/gaborcsardi/zip/master.svg)](https://codecov.io/github/gaborcsardi/zip?branch=master)

## Installation


```r
source("https://install-github.me/gaborcsardi/zip")
```

## Usage


```r
library(zip)
```

```
#> 
#> Attaching package: 'zip'
```

```
#> The following object is masked from 'package:utils':
#> 
#>     zip
```

### Creating ZIP files

`zip()` creates a new ZIP archive. (It overwrites the output file if it
exists.) Simply supply all directories and files that you want to include
in the archive.

It makes sense to change to the top-level directory of the files before
archiving them, so that the files are stored using a relative path name.


```r
zip("sources.zip", c("R", "src"))
file.info("sources.zip")
```

```
#>               size isdir mode               mtime               ctime
#> sources.zip 203203 FALSE  644 2017-04-10 09:36:35 2017-04-10 09:36:35
#>                           atime uid gid       uname grname
#> sources.zip 2017-04-10 09:35:22 501  20 gaborcsardi  staff
```

Directories are added recursively by default.

`zip_append()` is similar to `zip()`, but it appends files to an existing
ZIP archive.

### Listing ZIP files

`zip_list()` lists files in a ZIP archive. It returns a data frame:


```r
zip_list("sources.zip")
```

```
#>       filename compressed_size uncompressed_size
#> 1    R/utils.R             251               508
#> 2      R/zip.R             926              2412
#> 3   src/init.c             285               510
#> 4   src/init.o            1406              3388
#> 5  src/miniz.h           49202            226019
#> 6   src/rzip.c             624              1751
#> 7   src/rzip.o            2516              6132
#> 8    src/zip.c            4370             18582
#> 9    src/zip.h            1658              5389
#> 10   src/zip.o          100255            254228
#> 11  src/zip.so           40644             96680
```

### Uncompressing ZIP files

This is currently not supported by the `zip` package, but available from
base R, via `utils::unzip()`.

## License

CC0
