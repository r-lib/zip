rl16 <- function(b, o) as.integer(b[o + 1]) + 256L * as.integer(b[o + 2])
rl32 <- function(b, o) {
  as.integer(b[o + 1]) +
    256 * as.integer(b[o + 2]) +
    65536 * as.integer(b[o + 3]) +
    16777216 * as.integer(b[o + 4])
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
      if (!identical(keys$verifier, verifier)) {
        stop("wrong password")
      }
      mac <- .Call(c_R_crypto_hmac_sha1, keys$mac_key, ct)
      if (!identical(mac[1:10], authcode)) {
        stop("HMAC mismatch")
      }
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
  testthat::skip_on_cran()
  z <- Sys.which("7zz")
  if (!nzchar(z)) {
    z <- Sys.which("7z")
  }
  if (!nzchar(z)) {
    stop("7-Zip (7zz/7z) not available")
  }
  z
}

# zip a set of flat files from `root` into `zipfile`, encrypted.
zip_enc <- function(
  zipfile,
  files,
  root,
  password,
  encryption = "aes256",
  level = 6
) {
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
