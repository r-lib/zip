


# zip

> Cross-Platform 'zip' Compression

[![Linux Build Status](https://travis-ci.org/r-lib/zip.svg?branch=master)](https://travis-ci.org/r-lib/zip)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/r-lib/zip?svg=true)](https://ci.appveyor.com/project/gaborcsardi/zip)
[![](https://www.r-pkg.org/badges/version/zip)](https://www.r-pkg.org/pkg/zip)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/zip)](https://www.r-pkg.org/pkg/zip)
[![Coverage Status](https://img.shields.io/codecov/c/github/r-lib/zip/master.svg)](https://codecov.io/github/r-lib/zip?branch=master)

## Installation


```r
source("https://install-github.me/r-lib/zip")
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
#> sources.zip 273855 FALSE  644 2019-02-17 23:56:43 2019-02-17 23:56:43
#>                           atime uid gid       uname grname
#> sources.zip 2019-02-17 23:56:43 501  20 gaborcsardi  staff
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
#> 1    R/utils.R             738              2698
#> 2      R/zip.R            1535              4574
#> 3   src/init.c             316               633
#> 4   src/init.o            1441              3516
#> 5  src/miniz.c           54994            313426
#> 6  src/miniz.h           18060             66464
#> 7  src/miniz.o          123757            331616
#> 8   src/rzip.c            1836              5614
#> 9   src/rzip.o            6162             13464
#> 10  src/zip.so           64036            192016
```

### Uncompressing ZIP files

This is currently not supported by the `zip` package, but available from
base R, via `utils::unzip()`.

## License

CC0
