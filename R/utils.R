
dir_all <- function(files) {
  if (! length(files)) return(files)

  info <- file.info(files)

  unlist(lapply(
    seq_along(files),
    function(i) {
      if (info$isdir[i]) {
        dir(files[i], recursive = TRUE, full.names = TRUE)
      } else {
        files[i]
      }
    }
  ))
}

ignore_dirs_with_warning <- function(files) {
  info <- file.info(files)
  if (any(info$isdir)) {
    warning("directories ignored in zip file, specify recurse = TRUE")
    files <- files[!info$isdir]
  }
  files
}
