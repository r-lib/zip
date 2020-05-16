
#' @theme assets/extra.css assets/rd.js
#' @useDynLib zip, .registration = TRUE, .fixes = "c_"
NULL

#' Compress Files into 'zip' Archives
#'
#' `zip()` creates a new zip archive file.
#'
#' `zip_append()` appends compressed files to an existing 'zip' file.
#'
#' @section Permissions:
#'
#' `zip()` (and `zip_append()`, etc.) add the permissions of
#' the archived files and directories to the ZIP archive, on Unix systems.
#' Most zip and unzip implementations support these, so they will be
#' recovered after extracting the archive.
#'
#' Note, however that the owner and group (uid and gid) are currently
#' omitted, even on Unix.
#'
#' @section Relative paths:
#'
#' The difference between `zipr` and `zip` is how they handle the relative
#' paths of the input files.
#'
#' For `zip` (and `zip_append`), the root of the archive is supposed to
#' be the current working directory. The paths of the files are fully kept
#' in the archive. Absolute paths are also kept. Note that this might result
#' non-portable archives: some zip tools do not handle zip archives that
#' contain absolute file names, or file names that start with `../` or
#' `./`.
#'
#' E.g. for the following directory structure:
#' ```{r echo = FALSE}
#' dir.create(tmp <- tempdir())
#'
#' ```
#'
#' ```r
#'
#' foo
#'   bar
#'     file1
#'   bar2
#'     file2
#' foo2
#'   file3
#' ```
#'
#' Assuming the current working directory is `foo`, the following zip
#' entries are created by `zip`:
#' ```r
#' zip("x.zip", c("bar/file1", "bar2", "../foo2"))
#' zip_list("x.zip")$filename
#' #> bar/file1
#' #> bar2
#' #> bar2/file2
#' #> ../foo2
#' #> ../foo2/file3
#' ```
#'
#' For `zipr` (and `zipr_append`), each specified file or directory in
#' `files` is created as a top-level entry in the zip archive.
#' We suggest that you use `zipr` and `zipr_append` for new code, as they
#' don't create non-portable archives. For the same directory structure,
#' these zip entries are created:
#' ```r
#' zipr("x.zip", c("bar/file1", "bar2", "../foo2"))
#' zip_list("x.zip")$filename
#' #> file1
#' #> bar2
#' #> bar2/file2
#' #> foo2
#' #> foo2/file3
#' ```
#'
#' @section Custom file structure:
#'
#' Both `zipr` and `zip` allow manual specification of the file structure using
#' the names of `files`.
#'
#' Assuming files `bar/file1_2`, `dir1/file1_2`, `dir1/file2_2"` and `foo2` to
#' exist in the current working directory, the names can be used to produce a
#' custom file structure as follows:
#'
#' ```
#' zipr("x.zip", c("bar/file1_2", "dir1_2", "foo2"),
#'      keys = c("file1", "dir1", "foo2"))
#' zip_list("x.zip")$filename
#' #> file1
#' #> dir1
#' #> dir1/file1_2
#' #> dir1/file2_2
#' #> foo2
#' ```
#'
#' @param zipfile The zip file to create. If the file exists, `zip`
#'   overwrites it, but `zip_append` appends to it.
#' @param files List of file to add to the archive. See details below
#'    about absolute and relative path names.
#' @param recurse Whether to add the contents of directories recursively.
#' @param compression_level A number between 1 and 9. 9 compresses best,
#'   but it also takes the longest.
#' @param include_directories Whether to explicitly include directories
#'   in the archive. Including directories might confuse MS Office when
#'   reading docx files, so set this to `FALSE` for creating them.
#' @param keep_path Whether to keep the full path to `files` in the
#'   archive. See "Relative Paths" below for details. (`zip` and
#'   `zip_append` default to `TRUE`, `zipr` and `zipr_append` default
#'   to FALSE.)
#' @param keys Custom file names to set in the zip archive.
#' @return The name of the created zip file, invisibly.
#'
#' @export
#' @examples
#' ## Some files to zip up
#' dir.create(tmp <- tempfile())
#' cat("first file", file = file.path(tmp, "file1"))
#' cat("second file", file = file.path(tmp, "file2"))
#'
#' zipfile <- tempfile(fileext = ".zip")
#' zipr(zipfile, tmp)
#'
#' ## List contents
#' zip_list(zipfile)
#'
#' ## Add another file
#' cat("third file", file = file.path(tmp, "file3"))
#' zipr_append(zipfile, file.path(tmp, "file3"))
#' zip_list(zipfile)

zip <- function(zipfile, files, recurse = TRUE, compression_level = 9,
                include_directories = TRUE, keys = files) {
  zip_internal(zipfile, files, keys, recurse, compression_level,
               append = FALSE, include_directories = include_directories)
}

#' @rdname zip
#' @export
zipr <- function(zipfile, files, recurse = TRUE,
                 compression_level = 9, include_directories = TRUE,
                 keys = basename(normalizePath(files))) {
  zip_internal(zipfile, files, keys, recurse, compression_level,
               append = FALSE, include_directories = include_directories)
}

#' @rdname zip
#' @export

zip_append <- function(zipfile, files, recurse = TRUE,
                       compression_level = 9, include_directories = TRUE,
                       keys = files) {
  zip_internal(zipfile, files, keys, recurse, compression_level,
               append = TRUE, include_directories = include_directories)
}

#' @rdname zip
#' @export

zipr_append <- function(zipfile, files, recurse = TRUE,
                        compression_level = 9, include_directories = TRUE,
                        keys = basename(normalizePath(files))) {
  zip_internal(zipfile, files, keys, recurse, compression_level,
               append = TRUE, include_directories = include_directories)
}

zip_internal <- function(zipfile, files, keys, recurse, compression_level,
                         append, include_directories) {

  if (any(! file.exists(files))) stop("Some files do not exist")

  data <- get_zip_data(files, keys, recurse, include_directories)
  warn_for_dotdot(data$key)

  .Call(c_R_zip_zip, zipfile, data$key, data$file, data$dir,
        file.info(data$file)$mtime, as.integer(compression_level), append)

  invisible(zipfile)
}

#' List Files in a 'zip' Archive
#'
#' @param zipfile Path to an existing ZIP file.
#' @return A data frame with columns: `filename`, `compressed_size`,
#'   `uncompressed_size`, `timestamp`, `permissions`.
#'
#' @family zip/unzip functions
#' @export

zip_list <- function(zipfile) {
  zipfile <- normalizePath(zipfile)
  res <- .Call(c_R_zip_list, zipfile)
  df <- data.frame(
    stringsAsFactors = FALSE,
    filename = res[[1]],
    compressed_size = res[[2]],
    uncompressed_size = res[[3]],
    timestamp = as.POSIXct(res[[4]], tz = "UTC", origin = "1970-01-01")
  )
  df$permissions <- as.octmode(res[[5]])
  df
}

#' Uncompress 'zip' Archives
#'
#' `unzip()` always restores modification times of the extracted files and
#' directories.
#'
#' @section Permissions:
#'
#' If the zip archive stores permissions and was created on Unix,
#' the permissions will be restored.
#'
#' @param zipfile Path to the zip file to uncompress.
#' @param files Character vector of files to extract from the archive.
#'   Files within directories can be specified, but they must use a forward
#'   slash as path separator, as this is what zip files use internally.
#'   If `NULL`, all files will be extracted.
#' @param overwrite Whether to overwrite existing files. If `FALSE` and
#'   a file already exists, then an error is thrown.
#' @param junkpaths Whether to ignore all directory paths when creating
#'   files. If `TRUE`, all files will be created in `exdir`.
#' @param exdir Directory to uncompress the archive to. If it does not
#'   exist, it will be created.
#'
#' @export
#' @examples
#' ## Some files to zip up
#' dir.create(tmp <- tempfile())
#' cat("first file", file = file.path(tmp, "file1"))
#' cat("second file", file = file.path(tmp, "file2"))
#'
#' zipfile <- tempfile(fileext = ".zip")
#' zipr(zipfile, tmp)
#'
#' ## List contents
#' zip_list(zipfile)
#'
#' ## Extract
#' tmp2 <- tempfile()
#' unzip(zipfile, exdir = tmp2)

unzip <- function(zipfile, files = NULL, overwrite = TRUE,
                      junkpaths = FALSE, exdir = ".") {

  stopifnot(
    is_string(zipfile),
    is_character_or_null(files),
    is_flag(overwrite),
    is_flag(junkpaths),
    is_string(exdir))

  zipfile <- normalizePath(zipfile)
  mkdirp(exdir)
  exdir <- normalizePath(exdir)

  .Call(c_R_zip_unzip, zipfile, files, overwrite, junkpaths, exdir)

  invisible()
}
