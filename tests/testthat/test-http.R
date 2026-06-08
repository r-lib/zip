test_that("zip_list works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip))

  expect_snapshot(zip_list_snapshot(url, za$ex), transform = transform_offset)
})

test_that("unzip works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip))

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("unzip extracts specific files with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip))

  exdir <- test_temp_dir()
  target <- paste0(basename(za$ex), "/file1")
  unzip(url, files = target, exdir = exdir)

  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("zip_list falls back to full download when ranges unsupported", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "no-range"))

  expect_snapshot(zip_list_snapshot(url, za$ex), transform = transform_offset)
})

test_that("zip_list recovers when an oversized suffix range gives 416", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "suffix-416"))

  expect_snapshot(zip_list_snapshot(url, za$ex), transform = transform_offset)
})

test_that("unzip recovers when an oversized suffix range gives 416", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "suffix-416"))

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("unzip falls back to full download when ranges unsupported", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "no-range"))

  exdir <- test_temp_dir()
  expect_snapshot(unzip(url, exdir = exdir))
  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("unzip falls back to full download per entry when ranges drop out", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "mixed"))

  exdir <- test_temp_dir()
  expect_snapshot(unzip(url, exdir = exdir))
  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("unzip fetches data separately when entry range is truncated", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture()
  url <- range_server$url(zip_path(za$zip, "truncating"))

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("zip_list reads a ZIP64 EOCD archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip64()
  url <- range_server$url(zip_path(za$zip))

  expect_snapshot(zip_list_snapshot(url, za$ex), transform = transform_offset)
})

test_that("reads a real ZIP64 EOCD-record archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  # zip64.zip's classic EOCD has the cd_offset 0xFFFFFFFF sentinel, so the
  # real offset must be read from the ZIP64 EOCD record via its locator.
  # ext_attr has the S_IFREG high bit set; permissions must decode without
  # overflowing integer range.
  zf <- test_path("fixtures/zip64.zip")
  url <- range_server$url(zip_path(zf))

  expect_snapshot(
    zip_list_snapshot(url, sort = TRUE),
    transform = transform_offset
  )

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)
  expect_snapshot(extracted_tree(exdir))
})

test_that("unzip reads a ZIP64 EOCD archive over range requests", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- make_a_zip64()
  url <- range_server$url(zip_path(za$zip))

  exdir <- test_temp_dir()
  unzip(url, exdir = exdir)

  expect_snapshot(extracted_tree(exdir, za$ex))
})

test_that("unzip with junkpaths works with range request server", {
  skip_if_not_installed("curl")
  skip_if_not_installed("webfakes")

  za <- http_fixture(include_directories = FALSE)
  url <- range_server$url(zip_path(za$zip))

  exdir <- test_temp_dir()
  unzip(url, junkpaths = TRUE, exdir = exdir)

  expect_snapshot(extracted_tree(exdir))
})
