
#' @useDynLib ziplist64, .registration = TRUE, .fixes = "c_"
NULL

#' List Files in a 'zip' Archive
#'
#' @param zipfile Path to an existing ZIP file.
#' @return A data frame with columns: `filename`, `compressed_size`,
#'   `uncompressed_size`.
#'
#' @family zip/unzip functions
#' @export

zip_list <- function(zipfile) {
  zipfile <- normalizePath(zipfile)
  res <- .Call(c_R_zip_list, zipfile)
  data.frame(
    stringsAsFactors = FALSE,
    filename = res[[1]],
    compressed_size = res[[2]],
    uncompressed_size = res[[3]],
    timestamp = as.POSIXct(res[[4]], tz = "UTC", origin = "1970-01-01")
  )
}
