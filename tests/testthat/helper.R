transform_location <- function(x) {
  sub("@[a-zA-Z0-9._/]+:[0-9]+ \\([^)]+\\)", "@<location>", x)
}

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
      testthat::skip("cannot create big files")
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

# little-endian encode a non-negative integer into `n` raw bytes
le_bytes <- function(x, n) {
  as.raw(floor(x / 256^(0:(n - 1L))) %% 256)
}

# Turn a normal archive into one that uses a ZIP64 End of Central Directory
# record + locator, with the classic EOCD fields set to the saturation
# sentinels (0xFFFF / 0xFFFFFFFF). The central directory and local headers are
# left untouched, so the file stays small but forces the ZIP64 EOCD code path.
make_a_zip64 <- function(envir = parent.frame()) {
  za <- make_a_zip(envir = envir, include_directories = FALSE)
  raw_bytes <- readBin(za$zip, "raw", file.info(za$zip)$size)
  n <- length(raw_bytes)

  # classic EOCD is the trailing 22 bytes (zipr writes no archive comment)
  eocd_start <- n - 22L
  con <- rawConnection(raw_bytes[(eocd_start + 1L):n], "r")
  readBin(con, "raw", 4L) # signature
  readBin(con, "raw", 2L) # disk number
  readBin(con, "raw", 2L) # disk with CD start
  readBin(con, "raw", 2L) # entries on this disk
  num_entries <- read_u16(con)
  cd_size <- read_u32(con)
  cd_offset <- read_u32(con)
  close(con)

  # the ZIP64 EOCD record goes where the classic EOCD currently begins
  z64_rec_offset <- eocd_start

  z64_rec <- c(
    le_bytes(0x06064b50, 4L), # signature
    le_bytes(44, 8L), # size of remaining record (fixed part is 56 bytes)
    le_bytes(45, 2L), # version made by
    le_bytes(45, 2L), # version needed
    le_bytes(0, 4L), # number of this disk
    le_bytes(0, 4L), # disk with CD start
    le_bytes(num_entries, 8L), # entries on this disk
    le_bytes(num_entries, 8L), # total entries
    le_bytes(cd_size, 8L), # size of CD
    le_bytes(cd_offset, 8L) # offset of CD
  )
  z64_loc <- c(
    le_bytes(0x07064b50, 4L), # signature
    le_bytes(0, 4L), # disk with the ZIP64 EOCD record
    le_bytes(z64_rec_offset, 8L), # offset of the ZIP64 EOCD record
    le_bytes(1, 4L) # total number of disks
  )

  classic <- raw_bytes[(eocd_start + 1L):n]
  classic[11:12] <- as.raw(c(255L, 255L)) # num_entries sentinel
  classic[13:16] <- as.raw(rep(255L, 4L)) # cd_size sentinel
  classic[17:20] <- as.raw(rep(255L, 4L)) # cd_offset sentinel

  new_bytes <- c(raw_bytes[1:eocd_start], z64_rec, z64_loc, classic)

  zip64 <- test_temp_file(".zip", envir = envir)
  writeBin(new_bytes, zip64)
  list(zip = zip64, orig = za$zip, ex = za$ex)
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

range_server <- function(zipfile, envir = parent.frame()) {
  zip_bytes <- readBin(zipfile, "raw", file.info(zipfile)$size)
  app <- webfakes::new_app()
  app$locals$zip_bytes <- zip_bytes
  app$get("/file.zip", function(req, res) {
    zip_bytes <- req$app$locals$zip_bytes
    filesize <- length(zip_bytes)
    range_hdr <- req$get_header("range")
    if (is.null(range_hdr) || !nzchar(range_hdr)) {
      res$set_status(200L)$send(zip_bytes)
      return()
    }
    if (grepl("^bytes=-[0-9]+$", range_hdr)) {
      n <- as.integer(sub("bytes=-", "", range_hdr))
      start <- max(0L, filesize - n)
      end_byte <- filesize - 1L
    } else {
      m <- regmatches(
        range_hdr,
        regexec("bytes=([0-9]+)-([0-9]*)", range_hdr)
      )[[1]]
      start <- as.integer(m[2])
      end_byte <- if (!nzchar(m[3])) filesize - 1L else as.integer(m[3])
    }
    content <- zip_bytes[(start + 1L):(end_byte + 1L)]
    res$set_status(206L)$set_header(
      "Content-Range",
      sprintf("bytes %d-%d/%d", start, end_byte, filesize)
    )$set_header("Content-Type", "application/zip")$send(content)
  })
  webfakes::local_app_process(app, .local_envir = envir)
}

# A server that pretends it does not support range requests: it ignores the
# Range header entirely and always replies 200 with the whole file. Forces the
# fall-back-to-full-download code path in unzip()/zip_list().
no_range_server <- function(zipfile, envir = parent.frame()) {
  zip_bytes <- readBin(zipfile, "raw", file.info(zipfile)$size)
  app <- webfakes::new_app()
  app$locals$zip_bytes <- zip_bytes
  app$get("/file.zip", function(req, res) {
    zip_bytes <- req$app$locals$zip_bytes
    res$set_status(200L)$set_header(
      "Content-Type",
      "application/zip"
    )$send(zip_bytes)
  })
  webfakes::local_app_process(app, .local_envir = envir)
}

# Supports ranges for the EOCD/CD tail request (the suffix `bytes=-N`) but then
# returns 200 with the whole file for the explicit-range per-entry requests.
# Forces the per-entry full-download fallback in unzip_url().
mixed_range_server <- function(zipfile, envir = parent.frame()) {
  zip_bytes <- readBin(zipfile, "raw", file.info(zipfile)$size)
  app <- webfakes::new_app()
  app$locals$zip_bytes <- zip_bytes
  app$get("/file.zip", function(req, res) {
    zip_bytes <- req$app$locals$zip_bytes
    filesize <- length(zip_bytes)
    range_hdr <- req$get_header("range")
    # only honour suffix ranges (used for the EOCD/CD tail fetch); reply 200
    # with the whole file to anything else
    if (is.null(range_hdr) || !grepl("^bytes=-[0-9]+$", range_hdr)) {
      res$set_status(200L)$set_header(
        "Content-Type",
        "application/zip"
      )$send(zip_bytes)
      return()
    }
    n <- as.integer(sub("bytes=-", "", range_hdr))
    start <- max(0L, filesize - n)
    end_byte <- filesize - 1L
    content <- zip_bytes[(start + 1L):(end_byte + 1L)]
    res$set_status(206L)$set_header(
      "Content-Range",
      sprintf("bytes %d-%d/%d", start, end_byte, filesize)
    )$set_header("Content-Type", "application/zip")$send(content)
  })
  webfakes::local_app_process(app, .local_envir = envir)
}

# Supports ranges, but truncates any range that starts at a local file header to
# 40 bytes: enough to parse the header, never enough to include the compressed
# data. Forces the second (data-only) range fetch in unzip_url(). The follow-up
# request starts at the file data (not a PK\03\04 signature), so it is served
# in full.
truncating_range_server <- function(zipfile, envir = parent.frame()) {
  zip_bytes <- readBin(zipfile, "raw", file.info(zipfile)$size)
  app <- webfakes::new_app()
  app$locals$zip_bytes <- zip_bytes
  app$get("/file.zip", function(req, res) {
    zip_bytes <- req$app$locals$zip_bytes
    filesize <- length(zip_bytes)
    range_hdr <- req$get_header("range")
    if (is.null(range_hdr) || !nzchar(range_hdr)) {
      res$set_status(200L)$send(zip_bytes)
      return()
    }
    suffix <- grepl("^bytes=-[0-9]+$", range_hdr)
    if (suffix) {
      n <- as.integer(sub("bytes=-", "", range_hdr))
      start <- max(0L, filesize - n)
      end_byte <- filesize - 1L
    } else {
      m <- regmatches(
        range_hdr,
        regexec("bytes=([0-9]+)-([0-9]*)", range_hdr)
      )[[1]]
      start <- as.integer(m[2])
      end_byte <- if (!nzchar(m[3])) filesize - 1L else as.integer(m[3])
    }
    # Only truncate explicit-start per-entry requests, never the suffix range
    # used for the EOCD/CD tail (which on a small file starts at offset 0, i.e.
    # the first local header).
    lfh_sig <- as.raw(c(0x50, 0x4b, 0x03, 0x04))
    if (
      !suffix &&
        identical(zip_bytes[(start + 1L):(start + 4L)], lfh_sig) &&
        end_byte - start + 1L > 40L
    ) {
      end_byte <- start + 39L
    }
    content <- zip_bytes[(start + 1L):(end_byte + 1L)]
    res$set_status(206L)$set_header(
      "Content-Range",
      sprintf("bytes %d-%d/%d", start, end_byte, filesize)
    )$set_header("Content-Type", "application/zip")$send(content)
  })
  webfakes::local_app_process(app, .local_envir = envir)
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
  x <- sub("<tempdir>\\", "<tempdir>/", x, fixed = TRUE)
  x <- sub("\\R\\", "/R/", x, fixed = TRUE)
  x <- sub("[\\\\/]file[a-zA-Z0-9]+", "/<tempfile>", x)
  x <- sub("[A-Z]:.*Rtmp[a-zA-Z0-9]+[\\\\/]", "<tempdir>/", x)
  x
}

skip_if_not_installed <- function(...) {
  if (Sys.getenv("_R_CHECK_FORCE_SUGGESTS_") == "false") {
    testthat::skip_if_not_installed(...)
  }
}
