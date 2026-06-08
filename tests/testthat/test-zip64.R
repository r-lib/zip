test_that("zip_list reads a ZIP64 archive", {
  zf <- test_path("fixtures/zip64-extra.zip")
  lst <- zip_list(zf)

  expect_equal(
    lst$filename,
    c("src/file1", "src/file11", "src/dir/file2", "src/dir/file3")
  )
  expect_equal(lst$uncompressed_size, c(6, 7, 6, 6))
})

test_that("unzip extracts a ZIP64 archive", {
  zf <- test_path("fixtures/zip64-extra.zip")
  exdir <- test_temp_dir()
  unzip(zf, exdir = exdir)

  expect_equal(readLines(file.path(exdir, "src", "file1")), "file1")
  expect_equal(readLines(file.path(exdir, "src", "file11")), "file11")
  expect_equal(readLines(file.path(exdir, "src", "dir", "file2")), "file2")
  expect_equal(readLines(file.path(exdir, "src", "dir", "file3")), "file3")
})
