df <- function(key, file, dir = FALSE) {
  data_frame(
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

  Sys.chmod(file, "0644")
}

bns <- function(x) {
  paste0(basename(x), "/")
}

test_temp_file <- function(
  fileext = "",
  pattern = "test-file-",
  envir = parent.frame(),
  create = TRUE
) {
  tmp <- tempfile(pattern = pattern, fileext = fileext)
  if (identical(envir, .GlobalEnv)) {
    message("Temporary files will _not_ be cleaned up")
  } else {
    withr::defer(
      try(unlink(tmp, recursive = TRUE, force = TRUE), silent = TRUE),
      envir = envir
    )
  }
  if (create) {
    cat("", file = tmp)
    normalizePath(tmp)
  } else {
    tmp
  }
}

test_temp_dir <- function(
  pattern = "test-dir-",
  envir = parent.frame(),
  create = TRUE
) {
  tmp <- test_temp_file(pattern = pattern, envir = envir, create = FALSE)
  if (create) {
    dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
    normalizePath(tmp)
  } else {
    tmp
  }
}

make_a_zip <- function(
  mtime = Sys.time(),
  envir = parent.frame(),
  include_directories = TRUE
) {
  tmp <- test_temp_dir(envir = envir)
  cat("file1\n", file = file.path(tmp, "file1"))
  cat("file11\n", file = file.path(tmp, "file11"))
  dir.create(file.path(tmp, "dir"))
  cat("file2\n", file = file.path(tmp, "dir", "file2"))
  cat("file3\n", file = file.path(tmp, "dir", "file3"))

  Sys.setFileTime(file.path(tmp, "file1"), mtime)
  Sys.setFileTime(file.path(tmp, "file11"), mtime)
  Sys.setFileTime(file.path(tmp, "dir", "file2"), mtime)
  Sys.setFileTime(file.path(tmp, "dir", "file3"), mtime)
  Sys.setFileTime(file.path(tmp, "dir"), mtime)
  Sys.setFileTime(tmp, mtime)

  zip <- test_temp_file(".zip", envir = envir)
  zipr(zip, tmp, include_directories = include_directories)
  list(zip = zip, ex = tmp)
}

local_temp_dir <- function(
  pattern = "file",
  tmpdir = tempdir(),
  fileext = "",
  envir = parent.frame()
) {
  path <- tempfile(pattern = pattern, tmpdir = tmpdir, fileext = fileext)
  dir.create(path)
  setwd(path)
  do.call(
    withr::defer,
    list(
      bquote(unlink(.(path), recursive = TRUE)),
      envir = envir
    )
  )
  invisible(path)
}

transform_tempdir <- function(x) {
  x <- sub(tempdir(), "<tempdir>", x, fixed = TRUE)
  x <- sub(normalizePath(tempdir()), "<tempdir>", x, fixed = TRUE)
  x <- sub(
    normalizePath(tempdir(), winslash = "/"),
    "<tempdir>",
    x,
    fixed = TRUE
  )
  x <- sub("\\R\\", "/R/", x, fixed = TRUE)
  x <- sub("[\\\\/]file[a-zA-Z0-9]+", "/<tempfile>", x)
  x <- sub("[A-Z]:.*Rtmp[a-zA-Z0-9]+[\\\\/]", "<tempdir>/", x)
  x
}

