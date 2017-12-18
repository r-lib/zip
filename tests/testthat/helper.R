
df <- function(key, file, dir = FALSE) {
  data.frame(
    stringsAsFactors = FALSE,
    key = key,
    file = file,
    dir = dir
  )
}

make_big_file <- function(file, mb) {
  tryCatch(
    make_big_file1(file, mb),
    error = function(e) {
      try(unlink(file, recursive = TRUE), silent = TRUE)
      skip("cannot create big files")
    }
  )
}

make_big_file1 <- function(file, mb) {
  if (.Platform$OS.type == "windows") {
    .Call(c_R_make_big_file, file, as.integer(mb))

  } else if (Sys.info()["sysname"] == "Darwin") {
    .Call(c_R_make_big_file, file, as.integer(mb))

  } else if (nzchar(Sys.which("fallocate"))) {
    status <- system2("fallocate", c("-l", paste0(mb, "m"), shQuote(file)))
    if (status != 0) stop("Cannot create big files")

  } else if (nzchar(Sys.which("mkfile"))) {
    status <- system2("mkfile", c(paste0(mb, "m"), shQuote(file)))
    if (status != 0) stop("Cannot create big files")

  } else {
    stop("Cannot create big files")
  }
}
