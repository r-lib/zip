
context("zip_list")

test_that("can list a zip file", {

  dir.create(tmp <- tempfile())
  cat("first file", file = file.path(tmp, "file1"))
  cat("second file", file = file.path(tmp, "file2"))
  
  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip(zipfile, basename(tmp))
    )
  )

  expect_true(file.exists(zipfile))
  
  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c("file1", "file2")
  )

  expect_equal(
    colnames(list),
    c("filename", "compressed_size", "uncompressed_size")
  )
})
