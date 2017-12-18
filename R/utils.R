
get_zip_data <- function(files, recurse) {
  if (recurse && length(files)) {
    data <- do.call(rbind, lapply(files, get_zip_data_recursive))
    dup <- duplicated(data$files)
    if (any(dup)) data <- data[ !dup, drop = FALSE ]
    data

  } else {
    files <- ignore_dirs_with_warning(files)
    data.frame(
      stringsAsFactors = FALSE,
      key = basename(files),
      file = files,
      dir = rep(FALSE, length(files))
    )
  }
}

ignore_dirs_with_warning <- function(files) {
  info <- file.info(files)
  if (any(info$isdir)) {
    warning("directories ignored in zip file, specify recurse = TRUE")
    files <- files[!info$isdir]
  }
  files
}

get_zip_data_recursive <- function(x) {
  x <- normalizePath(x)
  wd <- getwd()
  on.exit(setwd(wd))
  setwd(dirname(x))
  bnx <- basename(x)

  files <- dir(
    bnx,
    recursive = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )

  key <- c(bnx, file.path(bnx, files))
  files <- c(x, file.path(dirname(x), bnx, files))
  dir <- file.info(files)$isdir
  key <- ifelse(dir, paste0(key, "/"), key)

  data.frame(
    stringsAsFactors = FALSE,
    key = key,
    file = files,
    dir = dir
  )
}
