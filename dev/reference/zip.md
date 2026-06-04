# Compress Files into 'zip' Archives

`zip()` creates a new zip archive file.

## Usage

``` r
zip(
  zipfile,
  files,
  recurse = TRUE,
  compression_level = 9,
  include_directories = TRUE,
  root = ".",
  mode = c("mirror", "cherry-pick"),
  keys = NULL
)

zipr(
  zipfile,
  files,
  recurse = TRUE,
  compression_level = 9,
  include_directories = TRUE,
  root = ".",
  mode = c("cherry-pick", "mirror"),
  keys = NULL
)

zip_append(
  zipfile,
  files,
  recurse = TRUE,
  compression_level = 9,
  include_directories = TRUE,
  root = ".",
  mode = c("mirror", "cherry-pick"),
  keys = NULL
)

zipr_append(
  zipfile,
  files,
  recurse = TRUE,
  compression_level = 9,
  include_directories = TRUE,
  root = ".",
  mode = c("cherry-pick", "mirror"),
  keys = NULL
)
```

## Arguments

- zipfile:

  The zip file to create. If the file exists, `zip` overwrites it, but
  `zip_append` appends to it. If it is a directory an error is thrown.

- files:

  Character vector of paths to files to add to the archive. See details
  below about absolute and relative path names.

- recurse:

  Whether to add the contents of directories recursively.

- compression_level:

  A number between 1 and 9. 9 compresses best, but it also takes the
  longest.

- include_directories:

  Whether to explicitly include directories in the archive. Including
  directories might confuse MS Office when reading docx files, so set
  this to `FALSE` for creating them.

- root:

  Change to this working directory before creating the archive.

- mode:

  Selects how files and directories are stored in the archive. It can be
  `"mirror"` or `"cherry-pick"`. See "Relative Paths" below for details.

- keys:

  An optional character vector of the same length as `files`, specifying
  the paths of the corresponding entries inside the zip archive. For a
  file, the key is the exact archive path. For a directory, the key
  becomes the directory prefix under which all contents are stored. If
  `NULL` (default), paths are determined by `mode`. `"."` may not appear
  in `files` when `keys` is specified.

## Value

The name of the created zip file, invisibly.

## Details

`zip_append()` appends compressed files to an existing 'zip' file.

### Relative paths

`zip()` and `zip_append()` can run in two different modes: mirror mode
and cherry picking mode. They handle the specified `files` differently.

#### Mirror mode

Mirror mode is for creating the zip archive of a directory structure,
exactly as it is on the disk. The current working directory will be the
root of the archive, and the paths will be fully kept. zip changes the
current directory to `root` before creating the archive.

E.g. consider the following directory structure:

    .
    |-- foo
    |   |-- bar
    |   |   |-- file1
    |   |   `-- file2
    |   `-- bar2
    `-- foo2
        `-- file3

Assuming the current working directory is `foo`, the following zip
entries are created by `zip`:

    setwd("foo")
    zip::zip("../test.zip", c("bar/file1", "bar2", "../foo2"))
    #> Warning in warn_for_dotdot(data$key): Some paths reference parent directory,
    #> creating non-portable zip file
    zip_list("../test.zip")[, "filename", drop = FALSE]
    #> # A data frame: 4 x 1
    #>   filename
    #>   <chr>
    #> 1 bar/file1
    #> 2 bar2/
    #> 3 ../foo2/
    #> 4 ../foo2/file3

Note that zip refuses to store files with absolute paths, and chops off
the leading `/` character from these file names. This is because only
relative paths are allowed in zip files.

#### Cherry picking mode

In cherry picking mode, the selected files and directories will be at
the root of the archive. This mode is handy if you want to select a
subset of files and directories, possibly from different paths and put
all of them in the archive, at the top level.

Here is an example with the same directory structure as above:

    zip::zip(
      "../test2.zip",
      c("bar/file1", "bar2", "../foo2"),
      mode = "cherry-pick"
    )
    zip_list("../test2.zip")[, "filename", drop = FALSE]
    #> # A data frame: 4 x 1
    #>   filename
    #>   <chr>
    #> 1 file1
    #> 2 bar2/
    #> 3 foo2/
    #> 4 foo2/file3

From zip version 2.3.0, `"."` has a special meaning in the `files`
argument: it will include the files (and possibly directories) within
the current working directory, but **not** the working directory itself.
Note that this only applies to cherry picking mode.

### Permissions:

`zip()` (and `zip_append()`, etc.) add the permissions of the archived
files and directories to the ZIP archive, on Unix systems. Most zip and
unzip implementations support these, so they will be recovered after
extracting the archive.

Note, however that the owner and group (uid and gid) are currently
omitted, even on Unix.

### `zipr()` and `zipr_append()`

These functions exist for historical reasons. They are identical to
`zip()` and `zip_append()` with a different default for the `mode`
argument.

## Examples

``` r
## Some files to zip up. We will run all this in the R session's
## temporary directory, to avoid messing up the user's workspace.
dir.create(tmp <- tempfile())
dir.create(file.path(tmp, "mydir"))
cat("first file", file = file.path(tmp, "mydir", "file1"))
cat("second file", file = file.path(tmp, "mydir", "file2"))

zipfile <- tempfile(fileext = ".zip")
zip::zip(zipfile, "mydir", root = tmp)

## List contents
zip_list(zipfile)
#> # A data frame: 3 × 8
#>   filename    compressed_size uncompressed_size timestamp           permissions
#>   <chr>                 <dbl>             <dbl> <dttm>              <octmode>  
#> 1 mydir/                    0                 0 2026-06-04 10:06:46 755        
#> 2 mydir/file1              15                10 2026-06-04 10:06:46 644        
#> 3 mydir/file2              16                11 2026-06-04 10:06:46 644        
#> # ℹ 3 more variables: crc32 <hexmode>, offset <dbl>, type <chr>

## Add another file
cat("third file", file = file.path(tmp, "mydir", "file3"))
zip_append(zipfile, file.path("mydir", "file3"), root = tmp)
zip_list(zipfile)
#> # A data frame: 4 × 8
#>   filename    compressed_size uncompressed_size timestamp           permissions
#>   <chr>                 <dbl>             <dbl> <dttm>              <octmode>  
#> 1 mydir/                    0                 0 2026-06-04 10:06:46 755        
#> 2 mydir/file1              15                10 2026-06-04 10:06:46 644        
#> 3 mydir/file2              16                11 2026-06-04 10:06:46 644        
#> 4 mydir/file3              15                10 2026-06-04 10:06:46 644        
#> # ℹ 3 more variables: crc32 <hexmode>, offset <dbl>, type <chr>
```
