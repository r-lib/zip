
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
