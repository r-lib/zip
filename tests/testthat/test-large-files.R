
test_that("large zip files", {
  skip_on_cran()

  tmp <- tempfile("zip-test-large-")
  tmpzip <- tempfile("zip-test-large-", fileext = ".zip")
  on.exit(unlink(c(tmp, tmpzip)), add = TRUE)

  oc <- file(tmp, open = "wb")
  for (i in 1:6) {
    data <- runif(1e7)
    writeBin(data, oc)
  }
  close(oc)

  zip::zip(tmpzip, tmp, compression_level = 0, mode = "cherry-pick")
  zip::zip_list(tmpzip)

  unlink(tmp)
  zip::unzip(tmpzip, exdir = dirname(tmp))

  expect_true(file.exists(tmp))

  expect_true(file.size(tmp) > 450000000)
  expect_true(file.size(tmpzip) > 450000000)
})

test_that("can compress / uncompress large files", {

  skip_on_cran()
  if (! nzchar(Sys.getenv("ZIP_LONG_TESTS")) &&
      ! nzchar(Sys.getenv("CI"))) {
    skip("takes long")
  }

  ## Note: it will be also skipped if we cannot find a reasonable quick
  ## way to create a 5GB file.

  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dir.create(tmp <- tempfile())
  file1 <- file.path(tmp, "file1")
  make_big_file(file1, 5000)
  size <- file.info(file1)$size

  zipfile <- tempfile(fileext = ".zip")
  on.exit(unlink(zipfile), add = TRUE)

  zipr(zipfile, file1, compression_level = 1)
  expect_true(file.exists(zipfile))
  list <- zip_list(zipfile)
  expect_equal(list$filename, "file1")
  expect_equal(list$uncompressed_size, size)

  on.exit(unlink(tmp2, recursive = TRUE), add = TRUE)
  dir.create(tmp2 <- tempfile())

  unlink(file1)
  zip::unzip(zipfile, exdir = tmp2)
  expect_equal(file.info(file.path(tmp2, "file1"))$size, size)
})

test_that("can compress / uncompress many files", {

  skip_on_cran()
  if (! nzchar(Sys.getenv("ZIP_LONG_TESTS")) &&
      ! nzchar(Sys.getenv("CI"))) {
    skip("takes long")
  }

  tmp <- test_temp_dir()
  for (i in 1:70000) cat("file", i, file = file.path(tmp, i))

  zip <- test_temp_file(".zip")
  zipr(zip, tmp)

  l <- zip_list(zip)
  expect_equal(nrow(l), 70001)

  tmp2 <- test_temp_dir()
  zip::unzip(zip, exdir = tmp2)
  expect_equal(
    length(dir(file.path(tmp2, basename(tmp)))),
    70000)
})
