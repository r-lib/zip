
#' @useDynLib zip, .registration = TRUE, .fixes = "c_"
NULL

#' Compress Files into 'zip' Archives
#'
#' `zip` creates a new zip archive file.
#'
#' `zip_append` appends compressed files to an existing 'zip' file.
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
#' zip(zipfile, tmp)
#'
#' ## List contents
#' zip_list(zipfile)
#'
#' ## Add another file
#' cat("third file", file = file.path(tmp, "file3"))
#' zip_append(zipfile, file.path(tmp, "file3"))
#' zip_list(zipfile)

zip <- function(zipfile, files, recurse = TRUE, compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = FALSE)
}

#' @rdname zip
#' @export

zip_append <- function(zipfile, files, recurse = TRUE,
                       compression_level = 9) {
  zip_internal(zipfile, files, recurse, compression_level, append = TRUE)
}

zip_internal <- function(zipfile, files, recurse, compression_level,
                         append) {

  if (any(! file.exists(files))) stop("Some files do not exist")

  if (recurse) {
    files <- dir_all(files)
  } else {
    files <- ignore_dirs_with_warning(files)
  }

  .Call(c_R_zip_zip, zipfile, files, as.integer(compression_level),
        append, PACKAGE = "zip")

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
    filename = res[[1]],
    compressed_size = res[[2]],
    uncompressed_size = res[[3]]
  )
}
