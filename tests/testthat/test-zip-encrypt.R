# Tests for the WinZip AES writer path (Step 2 of PASSWORD-SUPPORT-PLAN.md).
#
# The package cannot yet *read* encrypted archives (that is Step 3), so the
# writer is verified two independent ways:
#   1. by decrypting our own output in-process with the Step-1 crypto shims
#      (`read_winzip_aes()` below) -- always runs, no external dependency;
#   2. by extracting with the external 7-Zip CLI when it is installed.

rl16 <- function(b, o) as.integer(b[o + 1]) + 256L * as.integer(b[o + 2])
rl32 <- function(b, o) {
  as.integer(b[o + 1]) + 256 * as.integer(b[o + 2]) +
    65536 * as.integer(b[o + 3]) + 16777216 * as.integer(b[o + 4])
}

# Walk the local file headers of an archive, decrypt every WinZip AES (method
# 99) entry, and return a named list mapping entry path -> raw contents.
# Non-encrypted entries (e.g. directory entries) are skipped. Signals an error
# with message "wrong password" on a verifier mismatch and "HMAC mismatch" on
# an authentication failure, so tests can assert on those.
read_winzip_aes <- function(zipfile, password) {
  b <- readBin(zipfile, "raw", n = file.size(zipfile))
  pwbytes <- charToRaw(enc2utf8(password))
  out <- list()
  off <- 0L
  while (off + 4L <= length(b) && rl32(b, off) == 0x04034b50) {
    gpflag <- rl16(b, off + 6)
    method <- rl16(b, off + 8)
    csize <- rl32(b, off + 18)
    usize <- rl32(b, off + 22)
    fnlen <- rl16(b, off + 26)
    exlen <- rl16(b, off + 28)
    name <- rawToChar(b[(off + 30 + 1):(off + 30 + fnlen)])
    exoff <- off + 30 + fnlen
    dataoff <- exoff + exlen

    if (method == 99) {
      stopifnot(bitwAnd(gpflag, 1L) == 1L) # encrypted bit
      # locate the 0x9901 WinZip AES extra field
      strength <- NA_integer_
      realmethod <- NA_integer_
      p <- exoff
      while (p + 4L <= exoff + exlen) {
        id <- rl16(b, p)
        sz <- rl16(b, p + 2)
        if (id == 0x9901) {
          strength <- as.integer(b[p + 8 + 1])
          realmethod <- rl16(b, p + 9)
        }
        p <- p + 4L + sz
      }
      stopifnot(!is.na(strength))
      saltlen <- c(8L, 12L, 16L)[strength]
      salt <- b[(dataoff + 1):(dataoff + saltlen)]
      verifier <- b[(dataoff + saltlen + 1):(dataoff + saltlen + 2)]
      ctlen <- csize - saltlen - 2L - 10L
      ctbeg <- dataoff + saltlen + 2
      ct <- if (ctlen > 0) b[(ctbeg + 1):(ctbeg + ctlen)] else raw()
      authcode <- b[(ctbeg + ctlen + 1):(ctbeg + ctlen + 10)]

      keys <- .Call(c_R_crypto_winzip_keys, pwbytes, salt, strength)
      if (!identical(keys$verifier, verifier)) stop("wrong password")
      mac <- .Call(c_R_crypto_hmac_sha1, keys$mac_key, ct)
      if (!identical(mac[1:10], authcode)) stop("HMAC mismatch")
      plain <- .Call(c_R_crypto_aes_ctr, keys$enc_key, ct)
      if (realmethod == 8) {
        infl <- .Call(c_R_inflate, plain, 1L, as.integer(usize), TRUE)
        plain <- infl$output[seq_len(infl$bytes_written)]
      }
      stopifnot(length(plain) == usize)
      out[[name]] <- plain
    }
    off <- dataoff + csize
  }
  out
}

# Local-header summary of every entry: path, compression method, encrypted bit.
list_local_headers <- function(zipfile) {
  b <- readBin(zipfile, "raw", n = file.size(zipfile))
  rows <- list()
  off <- 0L
  while (off + 4L <= length(b) && rl32(b, off) == 0x04034b50) {
    gpflag <- rl16(b, off + 6)
    method <- rl16(b, off + 8)
    csize <- rl32(b, off + 18)
    fnlen <- rl16(b, off + 26)
    exlen <- rl16(b, off + 28)
    name <- rawToChar(b[(off + 30 + 1):(off + 30 + fnlen)])
    rows[[length(rows) + 1]] <- list(
      name = name,
      method = method,
      encrypted = bitwAnd(gpflag, 1L) == 1L
    )
    off <- off + 30 + fnlen + exlen + csize
  }
  rows
}

seven_zip <- function() {
  z <- Sys.which("7zz")
  if (!nzchar(z)) z <- Sys.which("7z")
  if (!nzchar(z)) testthat::skip("7-Zip (7zz/7z) not available")
  z
}

# zip a set of flat files from `root` into `zipfile`, encrypted.
zip_enc <- function(zipfile, files, root, password, encryption = "aes256",
                    level = 6) {
  zip_internal(
    zipfile,
    files = files,
    recurse = FALSE,
    compression_level = level,
    append = FALSE,
    root = root,
    keep_path = FALSE,
    include_directories = FALSE,
    password = password,
    encryption = encryption
  )
}

make_fixture_files <- function(dir) {
  writeLines("first fixture file", file.path(dir, "small.txt"))
  writeBin(raw(0), file.path(dir, "empty.txt"))
  writeLines(
    rep("The quick brown fox jumps over the lazy dog. 0123456789", 400),
    file.path(dir, "big.txt")
  )
  c("small.txt", "empty.txt", "big.txt")
}

test_that("our AES output decrypts back to the original (in-process)", {
  for (enc in c("aes256", "aes128")) {
    src <- withr::local_tempdir()
    names <- make_fixture_files(src)
    orig <- lapply(file.path(src, names), readBin, "raw", n = 1e6)
    names(orig) <- names

    zipfile <- withr::local_tempfile(fileext = ".zip")
    zip_enc(zipfile, file.path(src, names), src, "open sesame", enc)

    dec <- read_winzip_aes(zipfile, "open sesame")
    expect_setequal(names(dec), names)
    for (nm in names) expect_identical(dec[[nm]], orig[[nm]], info = nm)
  }
})

test_that("a wrong password is caught by the verifier", {
  src <- withr::local_tempdir()
  writeLines("hello", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "a.txt"), src, "right")

  expect_no_error(read_winzip_aes(zipfile, "right"))
  expect_error(read_winzip_aes(zipfile, "wrong"), "wrong password")
})

test_that("a non-ASCII (UTF-8) password round-trips", {
  pw <- "naïve-π" # naïve-π
  src <- withr::local_tempdir()
  writeLines("bonjour", file.path(src, "fr.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "fr.txt"), src, pw)

  dec <- read_winzip_aes(zipfile, pw)
  expect_identical(rawToChar(dec[["fr.txt"]]), "bonjour\n")
  # a password that differs only in its non-ASCII bytes must fail
  expect_error(read_winzip_aes(zipfile, "naive-pi"), "wrong password")
})

test_that("directory entries are added unencrypted alongside encrypted files", {
  src <- withr::local_tempdir()
  dir.create(file.path(src, "d"))
  writeLines("inside", file.path(src, "d", "f.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_internal(
    zipfile,
    files = "d", # relative to root, so keys stay relative
    recurse = TRUE,
    compression_level = 6,
    append = FALSE,
    root = src,
    keep_path = TRUE,
    include_directories = TRUE,
    password = "pw",
    encryption = "aes256"
  )
  hdrs <- list_local_headers(zipfile)
  names(hdrs) <- vapply(hdrs, `[[`, "", "name")
  # the file is encrypted (method 99); the directory entry is stored, unencrypted
  expect_true(hdrs[["d/f.txt"]]$encrypted)
  expect_equal(hdrs[["d/f.txt"]]$method, 99)
  expect_false(hdrs[["d/"]]$encrypted)
  expect_equal(hdrs[["d/"]]$method, 0)

  dec <- read_winzip_aes(zipfile, "pw")
  expect_identical(rawToChar(dec[["d/f.txt"]]), "inside\n")
  expect_false("d/" %in% names(dec)) # the directory entry is not encrypted
})

test_that("7-Zip can extract what we encrypt", {
  z <- seven_zip()
  for (enc in c("aes256", "aes128")) {
    src <- withr::local_tempdir()
    names <- make_fixture_files(src)
    zipfile <- withr::local_tempfile(fileext = ".zip")
    zip_enc(zipfile, file.path(src, names), src, "open sesame", enc)

    exdir <- withr::local_tempdir()
    status <- suppressWarnings(system2(
      z,
      c("x", "-y", "-p'open sesame'", paste0("-o", exdir), zipfile),
      stdout = FALSE, stderr = FALSE
    ))
    expect_equal(status, 0, info = enc)
    for (nm in names) {
      expect_equal(
        readBin(file.path(exdir, nm), "raw", n = 1e6),
        readBin(file.path(src, nm), "raw", n = 1e6),
        info = paste(enc, nm)
      )
    }
  }
})

test_that("7-Zip rejects the wrong password for our output", {
  z <- seven_zip()
  src <- withr::local_tempdir()
  writeLines("secret stuff", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "a.txt"), src, "correct horse")

  exdir <- withr::local_tempdir()
  status <- suppressWarnings(system2(
    z,
    c("x", "-y", "-pnope", paste0("-o", exdir), zipfile),
    stdout = FALSE, stderr = FALSE
  ))
  expect_gt(status, 0)
})

test_that("password = NULL is a no-op (unencrypted, backward compatible)", {
  src <- withr::local_tempdir()
  writeLines("plain text", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_internal(
    zipfile,
    files = file.path(src, "a.txt"),
    recurse = FALSE,
    compression_level = 6,
    append = FALSE,
    root = src,
    keep_path = FALSE,
    include_directories = FALSE,
    password = NULL
  )
  # no entry is flagged encrypted and no method-99 entry exists
  b <- readBin(zipfile, "raw", n = file.size(zipfile))
  expect_equal(rl32(b, 0), 0x04034b50)
  expect_equal(bitwAnd(rl16(b, 6), 1L), 0L) # encryption bit clear
  expect_false(rl16(b, 8) == 99)            # not method 99
  # and it still round-trips through the normal extractor
  exdir <- withr::local_tempdir()
  unzip(zipfile, exdir = exdir)
  expect_identical(
    readLines(file.path(exdir, "a.txt")),
    "plain text"
  )
})

test_that("password / encryption arguments are validated", {
  expect_null(resolve_password(NULL))
  expect_identical(resolve_password("abc"), charToRaw("abc"))
  expect_identical(resolve_password(function() "xy"), charToRaw("xy"))
  expect_identical(resolve_password(as.raw(1:3)), as.raw(1:3))
  expect_error(resolve_password(""), "must not be empty")
  expect_error(resolve_password(raw(0)), "must not be empty")
  expect_error(resolve_password(c("a", "b")), "must be a string")
  expect_error(resolve_password(NA_character_), "must be a string")

  expect_equal(encryption_code("aes256"), 3L)
  expect_equal(encryption_code("aes128"), 1L)
  expect_error(encryption_code("zipcrypto"), "not supported")
})
