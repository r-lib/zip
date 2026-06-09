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
    for (nm in names) {
      expect_identical(dec[[nm]], orig[[nm]], info = nm)
    }
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
      stdout = FALSE,
      stderr = FALSE
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
    stdout = FALSE,
    stderr = FALSE
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
  expect_false(rl16(b, 8) == 99) # not method 99
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
