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
  writeBin(charToRaw("bonjour\n"), file.path(src, "fr.txt"))
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
  writeBin(charToRaw("inside\n"), file.path(src, "d", "f.txt"))
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
    zip_enc(zipfile, file.path(src, names), src, "opensesame", enc)

    exdir <- withr::local_tempdir()
    status <- suppressWarnings(system2(
      z,
      c("x", "-y", "-popensesame", paste0("-o", exdir), zipfile),
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
  expect_equal(encryption_code("zipcrypto"), 4L)
})

test_that("ZipCrypto write is extractable by 7-Zip", {
  z <- seven_zip()
  src <- withr::local_tempdir()
  names <- make_fixture_files(src)
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, names), src, "opensesame", "zipcrypto")

  # zip_list can read the encrypted central directory
  lst <- zip_list(zipfile)
  expect_setequal(lst$filename, names)
  # compressed_size includes the 12-byte ZipCrypto header so it is >= 12
  expect_true(all(lst$compressed_size >= 12L))

  exdir <- withr::local_tempdir()
  status <- suppressWarnings(system2(
    z,
    c("x", "-y", "-popensesame", paste0("-o", exdir), zipfile),
    stdout = FALSE,
    stderr = FALSE
  ))
  expect_equal(status, 0)
  for (nm in names) {
    expect_equal(
      readBin(file.path(exdir, nm), "raw", n = 1e6),
      readBin(file.path(src, nm), "raw", n = 1e6),
      info = nm
    )
  }
})

# ---- Step 3: reader/extract path ----------------------------------------

test_that("unzip() round-trips AES-encrypted archives (zip then unzip)", {
  for (enc in c("aes256", "aes128")) {
    src <- withr::local_tempdir()
    names <- make_fixture_files(src)
    orig <- lapply(file.path(src, names), readBin, "raw", n = 1e6)
    names(orig) <- names

    zipfile <- withr::local_tempfile(fileext = ".zip")
    zip_enc(zipfile, file.path(src, names), src, "open sesame", enc)

    exdir <- withr::local_tempdir()
    unzip(zipfile, exdir = exdir, password = "open sesame")

    for (nm in names) {
      expect_identical(
        readBin(file.path(exdir, nm), "raw", n = 1e6),
        orig[[nm]],
        info = paste(enc, nm)
      )
    }
  }
})

test_that("unzip() round-trips ZipCrypto-encrypted archives", {
  src <- withr::local_tempdir()
  names <- make_fixture_files(src)
  orig <- lapply(file.path(src, names), readBin, "raw", n = 1e6)
  names(orig) <- names

  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, names), src, "opensesame", "zipcrypto")

  exdir <- withr::local_tempdir()
  unzip(zipfile, exdir = exdir, password = "opensesame")

  for (nm in names) {
    expect_identical(
      readBin(file.path(exdir, nm), "raw", n = 1e6),
      orig[[nm]],
      info = nm
    )
  }
})

test_that("unzip() rejects a wrong password with a clear error", {
  src <- withr::local_tempdir()
  writeLines("secret text", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "a.txt"), src, "correct horse")

  exdir <- withr::local_tempdir()
  expect_error(
    unzip(zipfile, exdir = exdir, password = "wrong"),
    "Wrong password"
  )
})

test_that("unzip() with wrong password fails on ZipCrypto archives", {
  src <- withr::local_tempdir()
  writeLines("secret text", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "a.txt"), src, "correct horse", "zipcrypto")

  exdir <- withr::local_tempdir()
  expect_error(
    unzip(zipfile, exdir = exdir, password = "wrong"),
    "Wrong password|Authentication|extract"
  )
})

test_that("unzip() errors clearly when no password given for encrypted entry", {
  src <- withr::local_tempdir()
  writeLines("secret text", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  zip_enc(zipfile, file.path(src, "a.txt"), src, "pw")

  exdir <- withr::local_tempdir()
  expect_error(
    unzip(zipfile, exdir = exdir),
    "encrypted but no password"
  )
})

test_that("unzip() extracts AES archives produced by 7-Zip (interop fixtures)", {
  for (strength in c("aes256", "aes192", "aes128")) {
    fixture <- test_path("fixtures", paste0(strength, ".zip"))
    exdir <- withr::local_tempdir()
    unzip(fixture, exdir = exdir, password = "secret")

    expect_equal(
      readLines(file.path(exdir, "a.txt")),
      "first fixture file",
      info = strength
    )
    expect_equal(
      readLines(file.path(exdir, "sub", "b.txt")),
      "second file in subdir",
      info = strength
    )
    expect_equal(
      length(readLines(file.path(exdir, "big.txt"))),
      400L,
      info = strength
    )
  }
})

test_that("unzip() extracts ZipCrypto archive produced by Info-ZIP (interop fixture)", {
  fixture <- test_path("fixtures", "zipcrypto.zip")
  exdir <- withr::local_tempdir()
  unzip(fixture, exdir = exdir, password = "secret")

  expect_equal(readLines(file.path(exdir, "a.txt")), "first fixture file")
  expect_equal(readLines(file.path(exdir, "sub", "b.txt")), "second file in subdir")
  expect_equal(length(readLines(file.path(exdir, "big.txt"))), 400L)
})

test_that("unzip() with password leaves unencrypted entries unaffected", {
  src <- withr::local_tempdir()
  writeLines("plain text", file.path(src, "a.txt"))
  zipfile <- withr::local_tempfile(fileext = ".zip")
  # create an unencrypted archive
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
  exdir <- withr::local_tempdir()
  # password is ignored for unencrypted entries
  unzip(zipfile, exdir = exdir, password = "ignored")
  expect_identical(readLines(file.path(exdir, "a.txt")), "plain text")
})
