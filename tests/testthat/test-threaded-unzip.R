test_that("threaded_unzip extracts a single zip", {
  z <- make_a_zip()
  exdir <- test_temp_dir()

  threaded_unzip(z$zip, exdir)

  expect_true(file.exists(file.path(exdir, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(exdir, basename(z$ex), "dir", "file2")))
  expect_equal(readLines(file.path(exdir, basename(z$ex), "file1")), "file1")
})

test_that("threaded_unzip extracts multiple zips into a single exdir", {
  z1 <- make_a_zip()
  z2 <- make_a_zip()
  exdir <- test_temp_dir()

  threaded_unzip(c(z1$zip, z2$zip), exdir)

  expect_true(file.exists(file.path(exdir, basename(z1$ex), "file1")))
  expect_true(file.exists(file.path(exdir, basename(z2$ex), "file1")))
})

test_that("threaded_unzip extracts multiple zips into separate exdirs", {
  z1 <- make_a_zip()
  z2 <- make_a_zip()
  d1 <- test_temp_dir()
  d2 <- test_temp_dir()

  threaded_unzip(c(z1$zip, z2$zip), c(d1, d2))

  expect_true(file.exists(file.path(d1, basename(z1$ex), "file1")))
  expect_false(file.exists(file.path(d1, basename(z2$ex), "file1")))
  expect_true(file.exists(file.path(d2, basename(z2$ex), "file1")))
})

test_that("threaded_unzip works with explicit num_threads = 1", {
  z1 <- make_a_zip()
  z2 <- make_a_zip()
  exdir <- test_temp_dir()

  threaded_unzip(c(z1$zip, z2$zip), exdir, num_threads = 1L)

  expect_true(file.exists(file.path(exdir, basename(z1$ex), "file1")))
  expect_true(file.exists(file.path(exdir, basename(z2$ex), "file1")))
})

test_that("threaded_unzip works with num_threads > number of files", {
  z <- make_a_zip()
  exdir <- test_temp_dir()

  threaded_unzip(z$zip, exdir, num_threads = 8L)

  expect_true(file.exists(file.path(exdir, basename(z$ex), "file1")))
})

test_that("threaded_unzip errors on a missing zip", {
  exdir <- test_temp_dir()

  expect_snapshot(
    error = TRUE,
    threaded_unzip("/nonexistent/path/file.zip", exdir)
  )
})

test_that("threaded_unzip reports all failures when multiple zips fail", {
  z <- make_a_zip()
  exdir <- test_temp_dir()

  expect_snapshot(
    error = TRUE,
    threaded_unzip(c(z$zip, "/bad1.zip", "/bad2.zip"), exdir),
    transform = transform_tempdir
  )
})

test_that("threaded_unzip stops when exdirs length is mismatched", {
  z1 <- make_a_zip()
  z2 <- make_a_zip()
  d1 <- test_temp_dir()

  expect_snapshot(
    error = TRUE,
    threaded_unzip(c(z1$zip, z2$zip), c(d1, d1, d1))
  )
})

test_that("threaded_unzip stops when passwords length is mismatched", {
  z1 <- make_a_zip()
  z2 <- make_a_zip()
  exdir <- test_temp_dir()

  expect_snapshot(
    error = TRUE,
    threaded_unzip(c(z1$zip, z2$zip), exdir, passwords = c("a", "b", "c"))
  )
})

test_that("get_num_threads uses zip_threads option", {
  withr::local_options(zip_threads = 4L)
  expect_equal(get_num_threads(), 4L)
})

test_that("get_num_threads uses ZIP_THREADS env var", {
  withr::with_envvar(c(ZIP_THREADS = "3"), {
    withr::local_options(zip_threads = NULL)
    expect_equal(get_num_threads(), 3L)
  })
})

test_that("get_num_threads option takes precedence over env var", {
  withr::with_envvar(c(ZIP_THREADS = "5"), {
    withr::local_options(zip_threads = 7L)
    expect_equal(get_num_threads(), 7L)
  })
})

test_that("get_num_threads uses Ncpus option", {
  withr::with_envvar(c(ZIP_THREADS = NA), {
    withr::local_options(zip_threads = NULL, Ncpus = 6L)
    expect_equal(get_num_threads(), 6L)
  })
})

test_that("get_num_threads: zip_threads and ZIP_THREADS take precedence over Ncpus", {
  withr::local_options(zip_threads = 7L, Ncpus = 6L)
  expect_equal(get_num_threads(), 7L)

  withr::with_envvar(c(ZIP_THREADS = "5"), {
    withr::local_options(zip_threads = NULL, Ncpus = 6L)
    expect_equal(get_num_threads(), 5L)
  })
})

test_that("get_num_threads defaults to 2", {
  withr::with_envvar(c(ZIP_THREADS = NA), {
    withr::local_options(zip_threads = NULL, Ncpus = NULL)
    expect_equal(get_num_threads(), 2L)
  })
})

test_that("get_num_threads errors on invalid Ncpus option", {
  withr::with_envvar(c(ZIP_THREADS = NA), {
    withr::local_options(zip_threads = NULL, Ncpus = 0L)
    expect_snapshot(error = TRUE, get_num_threads())
  })
})

test_that("get_num_threads errors on invalid zip_threads option", {
  withr::local_options(zip_threads = 0L)
  expect_snapshot(error = TRUE, get_num_threads())

  withr::local_options(zip_threads = "two")
  expect_snapshot(error = TRUE, get_num_threads())
})

test_that("get_num_threads errors on invalid ZIP_THREADS env var", {
  withr::with_envvar(c(ZIP_THREADS = "0"), {
    withr::local_options(zip_threads = NULL)
    expect_snapshot(error = TRUE, get_num_threads())
  })

  withr::with_envvar(c(ZIP_THREADS = "banana"), {
    withr::local_options(zip_threads = NULL)
    expect_snapshot(error = TRUE, get_num_threads())
  })
})
