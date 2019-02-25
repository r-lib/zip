
context("get_zip_data_path")

test_that("get_zip_data", {
  on.exit(try(unlink(tmp, recursive = TRUE)), add = TRUE)
  dir.create(tmp <- tempfile())

  expect_equal(
    get_zip_data_path_recursive(tmp),
    df(paste0(tmp, "/"), normalizePath(tmp), TRUE)
  )
  expect_equal(get_zip_data_path_recursive(tmp), get_zip_data_path(tmp, TRUE))

  foobar <- file.path(tmp, "foobar")
  cat("foobar", file = foobar)

  expect_equal(
    get_zip_data_path_recursive(foobar),
    df(foobar, normalizePath(foobar), FALSE)
  )
  expect_equal(get_zip_data_path_recursive(foobar), get_zip_data_path(foobar, TRUE))

  expect_equal(
    get_zip_data_path_recursive(tmp),
    df(c(paste0(tmp, "/"), file.path(tmp, "foobar")),
       normalizePath(c(tmp, foobar)),
       c(TRUE, FALSE)
       )
  )
  expect_equal(get_zip_data_path_recursive(tmp), get_zip_data_path(tmp, TRUE))

  expect_equal(
    withr::with_dir(tmp, get_zip_data_path_recursive(".")),
    df(c("./", "./foobar"),
       normalizePath(c(tmp, foobar)),
       c(TRUE, FALSE)
       )
  )
  withr::with_dir(tmp,
    expect_equal(get_zip_data_path_recursive("."), get_zip_data_path(".", TRUE))
  )

  dir.create(file.path(tmp, "empty"))
  dir.create(file.path(tmp, "foo"))
  bar <- file.path(tmp, "foo", "bar")
  cat("bar\n", file = bar)

  data <- df(
    c(paste0(tmp, "/"),
      paste0(file.path(tmp, "empty"), "/"),
      paste0(file.path(tmp, "foo"), "/"),
      file.path(tmp, "foo", "bar"),
      file.path(tmp, "foobar")),
    normalizePath(c(
      tmp, file.path(tmp, "empty"), file.path(tmp, "foo"),
      bar, file.path(tmp, "foobar"))),
    c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )
  data <- data[order(data$file), ]
  rownames(data) <- NULL

  data2 <- get_zip_data_path_recursive(tmp)
  data2  <- data2[order(data2$file), ]
  rownames(data2) <- NULL

  expect_equal(data2, data)
  expect_equal(get_zip_data_path(tmp, TRUE), data)

  expect_equal(
    get_zip_data_path(c(foobar, bar), TRUE),
    df(c(foobar, bar),
       normalizePath(c(foobar, bar)),
       c(FALSE, FALSE))
  )

  expect_equal(
    get_zip_data_path(file.path(tmp, "foo"), TRUE),
    df(c(paste0(file.path(tmp, "foo"), "/"), file.path(tmp, "foo", "bar")),
       normalizePath(c(file.path(tmp, "foo"), file.path(tmp, "foo", "bar"))),
       c(TRUE, FALSE)
       )
  )
})

test_that("get_zip_data relative paths", {

  on.exit(try(unlink(tmp, recursive = TRUE)), add = TRUE)
  dir.create(tmp <- tempfile())

  dir.create(file.path(tmp, "foo"))
  dir.create(file.path(tmp, "foo", "bar"))

  withr::with_dir(
    file.path(tmp, "foo"),
    expect_equal(
      get_zip_data_path(file.path("..", "foo"), TRUE),
      df(paste0(c(file.path("..", "foo"), file.path("..", "foo", "bar")), "/"),
         normalizePath(c(file.path(tmp, "foo"), file.path(tmp, "foo", "bar"))),
         c(TRUE, TRUE)
         )
    )
  )
})
