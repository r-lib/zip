test_that("can list a zip file", {
  dir.create(tmp <- tempfile())
  cat("first file", file = file.path(tmp, "file1"))
  cat("second file", file = file.path(tmp, "file2"))

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c(basename(tmp), "file1", "file2")
  )

  expect_equal(
    colnames(list),
    c(
      "filename",
      "compressed_size",
      "uncompressed_size",
      "timestamp",
      "permissions",
      "crc32",
      "offset",
      "type",
      "encryption"
    )
  )
  expect_true(is.numeric(list$offset))
  expect_true(inherits(list$crc32, 'hexmode'))
})

test_that("CP932-encoded filename is decoded to UTF-8 when encoding is set", {
  skip_if(
    inherits(try(iconv("x", "CP932", "CP932"), silent = TRUE), "try-error"),
    "CP932 encoding not supported"
  )
  zf <- test_path("fixtures/cp932.zip")
  lst <- zip_list(zf, encoding = "CP932")
  expect_equal(lst$filename, "\u30c6\u30b9\u30c8.txt")
  expect_equal(Encoding(lst$filename), "UTF-8")
})

test_that("unsupported encoding gives an error", {
  zf <- test_path("fixtures/cp932.zip")
  expect_error(
    zip_list(zf, encoding = "NOT-AN-ENCODING"),
    "unsupported encoding"
  )
})

test_that("CP437-encoded filename is decoded to UTF-8", {
  zf <- test_path("fixtures/cp437.zip")
  lst <- zip_list(zf)
  expect_equal(lst$filename, "catal\u00f1n.txt")
  expect_equal(Encoding(lst$filename), "UTF-8")
})

test_that("symlinks", {
  options(width = 200)
  zf <- test_path("fixtures/symlink.zip")
  expect_snapshot(zip_list(zf)$type)
})

test_that("zip_list works on files with STORED comp_size=0 quirk", {
  zf <- test_path("fixtures/stored-zero-compsize.zip")
  lst <- zip_list(zf)
  expect_equal(lst$filename, c("subdir/", "subdir/hello.txt"))
  expect_equal(lst$uncompressed_size, c(20, 30))
})

test_that("zip_list reads Info-ZIP forced ZIP64 (`zip -fz`)", {
  # Every entry has uncompressed_size set to the 0xFFFFFFFF sentinel + a ZIP64
  # extra field, including zero-length STORED directory entries. These used to
  # be rejected by the bundled miniz reader. See tools/extra/make-zip64-infozip.sh.
  zf <- test_path("fixtures/zip64.zip")
  lst <- zip_list(zf)
  expect_equal(
    lst$filename,
    c(
      "src/",
      "src/file11",
      "src/dir/",
      "src/dir/file3",
      "src/dir/file2",
      "src/file1"
    )
  )
  expect_equal(lst$uncompressed_size, c(0, 7, 0, 6, 6, 6))
})
