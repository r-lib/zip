
#' @useDynLib zip, .registration = TRUE, .fixes = "c_"
NULL

#' Compress Files into 'zip' Archives
#'
#' `zipr` and `zip` both create a new zip archive file.
#'
#' `zipr_append` and `zip_append` append compressed files to an
#' existing 'zip' file.
#'
#' The different between `zipr` and `zip` is how they handle the relative
#' paths of the input files.
#'
#' For `zip` (and `zip_append`), the root of the archive is supposed to
#' be the current working directory. The paths of the files are fully kept
#' in the archive. Absolute paths are also kept. Note that this might result
#' non-portable archives: some zip tools do not handle zip archives that
#' contain absolute file names, or file names that start with `..//` or
#' `./`. This behavior is kept for compatibility, and we suggest that you
#' use `zipr` and `zipr_append` for new code.
#'
#' E.g. for the following directory structure:
#' ```
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
#' ```
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
#' We suggest that you use `zip` and `zip_append` for new code, as they
#' don't create non-portable archives. For the same directory structure,
#' these zip entries are created:
#' ```
#' zipr("x.zip", c("bar/file1", "bar2", "../foo2"))
#' zip_list("x.zip")$filename
#' #> file1
#' #> bar2
#' #> bar2/file2
#' #> foo2
#' #> foo2/file3
#' ```
#'
#' @param zipfile The zip file to create. If the file exists, `zip`
#'   overwrites it, but `zip_append` appends to it.
#' @param files List of file to add to the archive. Absolute path names
#'   will be added as absolute path names, relative path names stay
#'   relative in the archive.
#' @param recurse Whether to add the contents of directories recursively.
#' @param compression_level A number between 1 and 9. 9 compresses best,
#'   but it also takes the longest.
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

zip <- function(zipfile, files, recurse = TRUE, compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = FALSE,
               keep_path = TRUE)
}

#' @rdname zip
#' @export

zipr <- function(zipfile, files, recurse = TRUE, compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = FALSE,
               keep_path = FALSE)
}

#' @rdname zip
#' @export

zip_append <- function(zipfile, files, recurse = TRUE,
                       compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = TRUE,
               keep_path = TRUE)
}

#' @rdname zip
#' @export

zipr_append <- function(zipfile, files, recurse = TRUE,
                        compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = TRUE,
               keep_path = FALSE)
}

zip_internal <- function(zipfile, files, recurse, compression_level,
                         append, keep_path) {

  if (any(! file.exists(files))) stop("Some files do not exist")

  data <- get_zip_data(files, recurse, keep_path)
  warn_for_dotdot(data$key)

  .Call(c_R_zip_zip, zipfile, data$key, data$file, data$dir,
        as.integer(compression_level), append, PACKAGE = "zip")

  invisible(zipfile)
}

#' List Files in a 'zip' Archive
#'
#' @param zipfile Path to an existing ZIP file.
#' @return A data frame with columns: `filename`, `compressed_size`,
#'   `uncompressed_size`.
#'
#' @family zip/unzip functions
#' @export

zip_list <- function(zipfile) {
  res <- .Call(c_R_zip_list, zipfile, PACKAGE = "zip")
  data.frame(
    stringsAsFactors = FALSE,
    filename = sub("[\\\\/]$", "", res[[1]]),
    compressed_size = res[[2]],
    uncompressed_size = res[[3]]
  )
}
