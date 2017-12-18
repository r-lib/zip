
context("get_zip_data")

test_that("get_zip_data", {
  on.exit(try(unlink(tmp, recursive = TRUE)), add = TRUE)
  dir.create(tmp <- tempfile())

  expect_equal(
    get_zip_data_recursive(tmp),
    df(paste0(basename(tmp), "/"), normalizePath(tmp), TRUE)
  )
  expect_equal(get_zip_data_recursive(tmp), get_zip_data(tmp, TRUE))

  foobar <- file.path(tmp, "foobar")
  cat("foobar", file = foobar)

  expect_equal(
    get_zip_data_recursive(foobar),
    df(basename(foobar), normalizePath(foobar), FALSE)
  )
  expect_equal(get_zip_data_recursive(foobar), get_zip_data(foobar, TRUE))

  expect_equal(
    get_zip_data_recursive(tmp),
    df(c(paste0(basename(tmp), "/"), file.path(basename(tmp), "foobar")),
       normalizePath(c(tmp, foobar)),
       c(TRUE, FALSE)
       )
  )
  expect_equal(get_zip_data_recursive(tmp), get_zip_data(tmp, TRUE))

  expect_equal(
    withr::with_dir(tmp, get_zip_data_recursive(".")),
    df(c(paste0(basename(tmp), "/"), file.path(basename(tmp), "foobar")),
       normalizePath(c(tmp, foobar)),
       c(TRUE, FALSE)
       )
  )
  withr::with_dir(tmp,
    expect_equal(get_zip_data_recursive("."), get_zip_data(".", TRUE))
  )

  dir.create(file.path(tmp, "empty"))
  dir.create(file.path(tmp, "foo"))
  bar <- file.path(tmp, "foo", "bar")
  cat("bar\n", file = bar)

  data <- df(
    c(paste0(basename(tmp), "/"),
      paste0(file.path(basename(tmp), "empty"), "/"),
      paste0(file.path(basename(tmp), "foo"), "/"),
      file.path(basename(tmp), "foo", "bar"),
      file.path(basename(tmp), "foobar")),
    normalizePath(c(
      tmp, file.path(tmp, "empty"), file.path(tmp, "foo"),
      bar, file.path(tmp, "foobar"))),
    c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )

  expect_equal(get_zip_data_recursive(tmp), data)
  expect_equal(get_zip_data(tmp, TRUE), data)

  expect_equal(
    get_zip_data(c(foobar, bar), TRUE),
    df(c("foobar", "bar"),
       normalizePath(c(foobar, bar)),
       c(FALSE, FALSE))
  )

  expect_equal(
    get_zip_data(file.path(tmp, "foo"), TRUE),
    df(c("foo/", "foo/bar"),
       normalizePath(c(file.path(tmp, "foo"), file.path(tmp, "foo", "bar"))),
       c(TRUE, FALSE)
       )
  )
})
