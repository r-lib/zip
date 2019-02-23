
os_type <- function() {
  .Platform$OS.type
}

get_tool <- function (prog) {
  if (os_type() == "windows") prog <- paste0(prog, ".exe")

  exe <- system.file(package = "zip", "bin", .Platform$r_arch, prog)
    if (exe == "") {
      pkgpath <- system.file(package = "zip")
      if (basename(pkgpath) == "inst") pkgpath <- dirname(pkgpath)
      exe <- file.path(pkgpath, "src", "tools", prog)
      if (!file.exists(exe)) return("")
    }
  exe
}

unzip_exe <- function() {
  get_tool("unzip")
}

zip_exe <- function() {
  get_tool("zip")
}

zip_data <- new.env(parent = emptyenv())

## R CMD check fix
super <- ""

#' Create an external unzip process
#'
#' `unzip_process()` return an R6 class that represents an unzip process.
#' `make_unzip_process()` is a shorthand that also creates an instance of
#' this class.
#'
#' @param zipfile Path to the zip file to uncompress.
#' @param exdir Directory to uncompress the archive to. If it does not
#'   exist, it will be created.
#' @return An unzip process object, its class inherits from the
#'   [processx::process] class.
#'
#' @export

make_unzip_process <- function(zipfile, exdir) {
  unzip_class <- unzip_process()
  unzip_class$new(zipfile, exdir)
}

#' @export
#' @rdname make_unzip_process

unzip_process <- function() {
  need_packages(c("processx", "R6"), "creating unzip processes")
  zip_data$unzip_class <- zip_data$unzip_class %||%
    R6::R6Class(
      "unzip_process",
      inherit = processx::process,
      public = list(
        initialize = function(zipfile, exdir) {
          private$zipfile <- zipfile
          private$exdir <- exdir
          super$initialize(unzip_exe(), c(zipfile, exdir),
                           poll_connection = TRUE, stderr = tempfile())
        }
      ),
      private = list(
        zipfile = NULL,
        exdir = NULL
      )
    )

  zip_data$unzip_class
}

#' Create an external zip process
#'
#' `zip_process()` return an R6 class that represents a zip process.
#' `make_zip_process()` is a shorthand that also creates an instance of
#' this class.
#'
#' @param zipfile Path to the zip file to create.
#' @param files List of file to add to the archive. Each specified file
#'   or directory in is created as a top-level entry in the zip archive.
#' @param recurse Whether to add the contents of directories recursively.
#' @return A zip process object, its class inherits from the
#'   [processx::process] class.
#'
#' @export

make_zip_process <- function(zipfile, files, recurse = TRUE) {
  zip_class <- zip_process()
  zip_class$new(zipfile, files, recurse)
}

#' @export
#' @rdname make_zip_process

zip_process <- function() {
  need_packages(c("processx", "R6"), "creating zip processes")
  zip_data$zip_class <- zip_data$zip_class %||%
    R6::R6Class(
      "zip_process",
      inherit = processx::process,
      public = list(
        initialize = function(zipfile, files, recurse = TRUE) {
          private$zipfile <- zipfile
          private$files <- files
          private$recurse <- recurse
          private$params_file <- tempfile()
          write_zip_params(files, recurse, private$params_file)
          super$initialize(zip_exe(), c(zipfile, private$params_file),
                           poll_connection = TRUE, stderr = tempfile())
        }
      ),
      private = list(
        zipfile = NULL,
        files = NULL,
        recurse = NULL,
        params_file = NULL
      )
    )

  zip_data$zip_class
}

write_zip_params <- function(files, recurse, outfile) {
  data <- get_zip_data(files, recurse, keep_path = FALSE)
  mtime <- as.double(file.info(data$file)$mtime)

  con <- file(outfile, open = "wb")
  on.exit(close(con))

  ## Number of files
  writeBin(con = con, as.integer(nrow(data)))

  ## Key, first total length
  writeBin(con = con, as.integer(sum(nchar(data$key, type = "bytes") + 1L)))
  writeBin(con = con, data$key)

  ## Filenames
  writeBin(con = con, as.integer(sum(nchar(data$file, type = "bytes") + 1L)))
  writeBin(con = con, data$file)

  ## Is dir or not
  writeBin(con = con, as.integer(data$dir))

  ## mtime
  writeBin(con = con, mtime)
}
