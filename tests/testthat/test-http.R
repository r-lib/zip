test_that("zip_list works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  lst <- zip_list(url)

  expect_equal(
    colnames(lst),
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
  lst_local <- zip_list(za$zip)
  expect_equal(lst$filename, lst_local$filename)

  expect_true(inherits(lst$crc32, "hexmode"))
  expect_true(is.numeric(lst$offset))
})

test_that("unzip works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  result <- unzip(url, exdir = exdir)

  expect_true(file.exists(file.path(exdir, basename(za$ex), "file1")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "file11")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "dir", "file2")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "dir", "file3")))
  f1 <- file.path(exdir, basename(za$ex), "file1")
  f2 <- file.path(exdir, basename(za$ex), "dir", "file2")
  expect_equal(readLines(f1), "file1")
  expect_equal(readLines(f2), "file2")
})

test_that("unzip extracts specific files with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  target <- paste0(basename(za$ex), "/file1")
  result <- unzip(url, files = target, exdir = exdir)

  expect_true(file.exists(file.path(exdir, basename(za$ex), "file1")))
  expect_false(file.exists(file.path(exdir, basename(za$ex), "file11")))
  expect_equal(nrow(result), 1L)
})

test_that("zip_list falls back to full download when ranges unsupported", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- no_range_server(za$zip)
  url <- proc$url("/file.zip")

  lst <- zip_list(url)
  lst_local <- zip_list(za$zip)
  expect_equal(lst, lst_local)
})

test_that("unzip falls back to full download when ranges unsupported", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- no_range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  result <- unzip(url, exdir = exdir)

  expect_true(file.exists(file.path(exdir, basename(za$ex), "file1")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "file11")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "dir", "file2")))
  expect_true(file.exists(file.path(exdir, basename(za$ex), "dir", "file3")))
  f1 <- file.path(exdir, basename(za$ex), "file1")
  f2 <- file.path(exdir, basename(za$ex), "dir", "file2")
  expect_equal(readLines(f1), "file1")
  expect_equal(readLines(f2), "file2")
})

test_that("unzip falls back to full download per entry when ranges drop out", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- mixed_range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  f1 <- file.path(exdir, basename(za$ex), "file1")
  f2 <- file.path(exdir, basename(za$ex), "dir", "file2")
  expect_true(file.exists(f1))
  expect_equal(readLines(f1), "file1")
  expect_equal(readLines(f2), "file2")
})

test_that("unzip fetches data separately when entry range is truncated", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip()
  proc <- truncating_range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  f1 <- file.path(exdir, basename(za$ex), "file1")
  f2 <- file.path(exdir, basename(za$ex), "dir", "file2")
  expect_true(file.exists(f1))
  expect_equal(readLines(f1), "file1")
  expect_equal(readLines(f2), "file2")
})

test_that("zip_list reads a ZIP64 EOCD archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip64()
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  lst <- zip_list(url)
  ref <- zip_list(za$orig)

  expect_equal(lst$filename, ref$filename)
  expect_equal(lst$uncompressed_size, ref$uncompressed_size)
  expect_equal(lst$offset, ref$offset)
})

test_that("reads a real ZIP64 EOCD-record archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  # zip64.zip's classic EOCD has the cd_offset 0xFFFFFFFF sentinel, so the
  # real offset must be read from the ZIP64 EOCD record via its locator.
  zf <- test_path("fixtures/zip64.zip")
  proc <- range_server(zf)
  url <- proc$url("/file.zip")

  lst <- zip_list(url)
  files <- lst[lst$type == "file", ]
  expect_equal(
    sort(files$filename),
    c("src/dir/file2", "src/dir/file3", "src/file1", "src/file11")
  )
  # ext_attr has the S_IFREG high bit set; permissions must decode without
  # overflowing integer range.
  expect_equal(as.character(files$permissions), rep("644", 4))

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)
  expect_equal(readLines(file.path(exdir, "src", "file1")), "file1")
  expect_equal(readLines(file.path(exdir, "src", "dir", "file2")), "file2")
})

test_that("unzip reads a ZIP64 EOCD archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip64()
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  f1 <- file.path(exdir, basename(za$ex), "file1")
  f2 <- file.path(exdir, basename(za$ex), "dir", "file2")
  expect_true(file.exists(f1))
  expect_equal(readLines(f1), "file1")
  expect_equal(readLines(f2), "file2")
})

test_that("unzip with junkpaths works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip(include_directories = FALSE)
  proc <- range_server(za$zip)
  url <- proc$url("/file.zip")

  exdir <- test_temp_dir()
  unzip(url, junkpaths = TRUE, exdir = exdir)

  expect_equal(
    sort(list.files(exdir, recursive = TRUE)),
    c("file1", "file11", "file2", "file3")
  )
})
