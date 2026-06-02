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
      "type"
    )
  )
  expect_true(is.numeric(list$offset))
  expect_true(inherits(list$crc32, 'hexmode'))
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
