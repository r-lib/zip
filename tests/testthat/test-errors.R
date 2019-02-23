
context("errors")

test_that("non-existant file", {

  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))
  tmp <- tempfile()

  zipfile <- tempfile(fileext = ".zip")

  expect_error(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp))
    ),
    "Some files do not exist"
  )
})

test_that("appending non-existant file", {

  on.exit(try(unlink(c(zipfile, tmp, tmp2), recursive = TRUE)))
  cat("compress this if you can!", file = tmp <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp))
    )
  )

  cat("compress this as well, if you can!", file = tmp2 <- tempfile())

  expect_silent(
    withr::with_dir(
      dirname(tmp2),
      zipr_append(zipfile, basename(tmp2))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(basename(list$filename), basename(c(tmp, tmp2)))
})

test_that("non readable file", {

  skip_on_os("windows")
  skip_on_os("linux")

  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))
  cat("compress this if you can!", file = tmp <- tempfile())
  Sys.chmod(tmp, "0000")

  zipfile <- tempfile(fileext = ".zip")

  expect_error(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp))
    ),
    "Cannot add file"
  )
})

test_that("empty archive, no files", {
  on.exit(try(unlink(zipfile)))
  zipfile <- tempfile(fileext = ".zip")

  expect_silent(zipr(zipfile, character()))

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(nrow(list), 0)
  expect_equal(list$filename, character())
})

test_that("single empty directory", {
  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))
  dir.create(tmp <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(nrow(list), 1)
  expect_equal(list$filename, bns(tmp))

  dir.create(tmp2 <- tempfile())
  on.exit(try(unlink(tmp2, recursive = TRUE)))
  utils::unzip(zipfile, exdir = tmp2)
  expect_equal(dir(tmp2), basename(tmp))
  expect_true(file.info(file.path(tmp2, dir(tmp2)))$isdir)
})

test_that("single empty directory, non-recursive", {
  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))
  dir.create(tmp <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_warning(
    withr::with_dir(
      dirname(tmp),
      zipr(zipfile, basename(tmp), recurse = FALSE)
    ),
    "directories ignored"
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(nrow(list), 0)
  expect_equal(list$filename, character())
})

test_that("appending single empty directory", {

  on.exit(try(unlink(c(zipfile, tmp, tmp2), recursive = TRUE)))

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

  dir.create(tmp2 <- tempfile())

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zipr_append(zipfile, basename(tmp2))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c(basename(tmp), "file1", "file2", basename(tmp2))
  )
})

test_that("appending single empty directory, non-recursive", {

  on.exit(try(unlink(c(zipfile, tmp, tmp2), recursive = TRUE)))

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

  dir.create(tmp2 <- tempfile())

  expect_warning(
    withr::with_dir(
      dirname(tmp),
      zipr_append(zipfile, basename(tmp2), recurse = FALSE)
    ),
    "directories ignored"
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c(basename(tmp), "file1", "file2")
  )
})
