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

zip_list_snapshot <- function(x, root = NULL, sort = FALSE) {
  withr::local_options(width = 200)
  lst <- zip_list(x)
  if (!is.null(root)) {
    lst$filename <- sub(basename(root), "<root>", lst$filename, fixed = TRUE)
  }
  if (sort) {
    lst <- lst[order(lst$filename), , drop = FALSE]
  }
  lst$timestamp <- NULL
  lst <- as.data.frame(lst)
  rownames(lst) <- NULL
  print(lst)
  invisible(lst)
}

# offset may change because of the random temporary file/dir names
transform_offset <- function(x) {
  sub("([0-9a-f]{8}) +[0-9]+", "\\1 <offset>", x)
}

extracted_tree <- function(dir, root = NULL) {
  withr::local_options(width = 200)
  files <- sort(list.files(dir, recursive = TRUE))
  contents <- vapply(
    file.path(dir, files),
    function(f) paste(readLines(f), collapse = "\n"),
    character(1),
    USE.NAMES = FALSE
  )
  if (!is.null(root)) {
    files <- sub(basename(root), "<root>", files, fixed = TRUE)
  }
  out <- data.frame(path = files, contents = contents, stringsAsFactors = FALSE)
  print(out)
  invisible(out)
}

http_fixture <- function(include_directories = TRUE) {
  name <- if (include_directories) "http.zip" else "http-nodirs.zip"
  list(zip = test_path("fixtures", name), ex = "ziptest")
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
  za <- http_fixture(include_directories = FALSE)
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

# A single webfakes app backing all HTTP range-request tests. Rather than
# baking a particular ZIP into the app, each request names the file to serve via
# the `path` query parameter (read fresh from disk on every request) and selects
# the server's range-request behaviour via the first path segment (`mode`):
#
#   range       - full byte-range support
#   no-range    - ignores the Range header, always replies 200 with the whole
#                 file (forces the full-download fallback in unzip()/zip_list())
#   mixed       - honours only the suffix range used for the EOCD/CD tail; replies
#                 200 with the whole file to explicit per-entry ranges (forces the
#                 per-entry full-download fallback in unzip_url())
#   truncating  - honours ranges, but truncates a range starting at a local file
#                 header to 40 bytes: enough to parse the header, never enough to
#                 include the compressed data (forces the second, data-only range
#                 fetch in unzip_url()). The follow-up request starts at the file
#                 data, not a PK\03\04 signature, so it is served in full.
#   suffix-416  - honours explicit ranges, but rejects a suffix range larger than
#                 the file with 416 Range Not Satisfiable (as GitHub's CDN does),
#                 reporting the size in the Content-Range header ("bytes */SIZE").
#                 Forces the 416 recovery path in zip_fetch_cd().
#
# The handler runs in a separate R process (webfakes::new_app_process), so it
# must be self-contained: it may only reference req/res and base R.
range_server_app <- function() {
  app <- webfakes::new_app()
  app$get("/:mode/file.zip", function(req, res) {
    mode <- req$params$mode
    zipfile <- req$query$path
    zip_bytes <- readBin(zipfile, "raw", file.info(zipfile)$size)
    filesize <- length(zip_bytes)
    range_hdr <- req$get_header("range")

    send_full <- function() {
      res$set_status(200L)$set_header(
        "Content-Type",
        "application/zip"
      )$send(zip_bytes)
    }
    send_range <- function(start, end_byte) {
      content <- zip_bytes[(start + 1L):(end_byte + 1L)]
      res$set_status(206L)$set_header(
        "Content-Range",
        sprintf("bytes %d-%d/%d", start, end_byte, filesize)
      )$set_header("Content-Type", "application/zip")$send(content)
    }

    suffix <- !is.null(range_hdr) && grepl("^bytes=-[0-9]+$", range_hdr)

    # No Range header, or a mode/request combination that declines ranges, falls
    # back to serving the whole file with a 200.
    no_range <- is.null(range_hdr) || !nzchar(range_hdr)
    if (no_range || mode == "no-range" || (mode == "mixed" && !suffix)) {
      return(send_full())
    }

    # Reject an oversized suffix range with 416, reporting the size so the
    # client can recover.
    if (mode == "suffix-416" && suffix) {
      n <- as.integer(sub("bytes=-", "", range_hdr))
      if (n >= filesize) {
        return(
          res$set_status(416L)$set_header(
            "Content-Range",
            sprintf("bytes */%d", filesize)
          )$send("")
        )
      }
    }

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

    # Truncate explicit-start per-entry requests, never the suffix range used for
    # the EOCD/CD tail (which on a small file starts at offset 0, i.e. the first
    # local header).
    if (mode == "truncating") {
      lfh_sig <- as.raw(c(0x50, 0x4b, 0x03, 0x04))
      if (
        !suffix &&
          identical(zip_bytes[(start + 1L):(start + 4L)], lfh_sig) &&
          end_byte - start + 1L > 40L
      ) {
        end_byte <- start + 39L
      }
    }

    send_range(start, end_byte)
  })
  app
}

# A single persistent server process backs every HTTP test, instead of spawning
# one per test_that() block. Tests build their URL with range_server$url() and
# zip_path(), choosing the file and behaviour mode per request. Created only when
# webfakes is available; the HTTP tests skip otherwise.
range_server <- if (requireNamespace("webfakes", quietly = TRUE)) {
  webfakes::new_app_process(range_server_app())
}

# Build the path (with query string) under range_server that serves `zipfile`
# with the given range-request behaviour mode. Used as range_server$url(...).
zip_path <- function(zipfile, mode = "range") {
  paste0(
    "/",
    mode,
    "/file.zip?path=",
    utils::URLencode(normalizePath(zipfile), reserved = TRUE)
  )
}

transform_tempdir <- function(x) {
  x <- sub("^/private/tmp/", "/tmp/", x)
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
