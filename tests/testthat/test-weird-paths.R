test_that("warning for colon", {
  skip_on_os("windows")

  tmpzip <- tempfile("zip-test-colon-", fileext = ".zip")
  dir.create(tmp <- tempfile("zip-test-colon-"))
  on.exit(unlink(c(tmp, tmpzip), recursive = TRUE), add = TRUE)

  writeLines("boo", file.path(tmp, "bad:boy"))
  expect_warning(
    zip(tmpzip, tmp, mode = "cherry-pick"),
    "Some paths include a `:` character"
  )

  expect_true(file.exists(tmpzip))
  expect_equal(
    basename(zip_list(tmpzip)$filename[2]),
    "bad:boy"
  )
})

test_that("absolute paths lose leading /", {
  skip_on_os("windows")

  tmpzip <- tempfile("zip-test-sbs-", fileext = ".zip")
  dir.create(tmp <- tempfile("zip-test-abs-"))
  on.exit(unlink(c(tmp, tmpzip), recursive = TRUE), add = TRUE)

  writeLines("boo", file.path(tmp, "bad"))
  expect_warning(
    zip(tmpzip, tmp, mode = "mirror"),
    "Dropping leading `/` from paths"
  )

  expect_true(file.exists(tmpzip))
  expect_equal(
    paste0("/", zip_list(tmpzip)$filename[1]),
    paste0(tmp, "/")
  )
})

test_that("backslash is an error", {
  skip_on_os("windows")

  tmpzip <- tempfile("zip-test-bs-", fileext = ".zip")
  dir.create(tmp <- tempfile("zip-test-bs-"))
  on.exit(unlink(c(tmp, tmpzip), recursive = TRUE), add = TRUE)

  writeLines("boo", file.path(tmp, "real\\bad"))
  expect_snapshot(
    error = TRUE,
    zip(tmpzip, tmp, mode = "cherry-pick"),
    transform = function(x) {
      x <- transform_tempdir(x)
      x <- gsub("zip-test-bs-[^./]+\\b", "zip-test-bs-<random>", x)
      x <- sub("file zip.c:[0-9]+", "file zip.c:<line>", x)
      x
    }
  )
})

test_that("extracting absolute path", {
  abs <- test_path("fixtures", "abs.zip")
  dir.create(tmp <- tempfile("zip-test-xabs-"))
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  unzip(abs, exdir = tmp)
  expect_true(file.exists(file.path(tmp, "tmp")))
  expect_true(file.exists(file.path(tmp, "tmp", "boo")))
  expect_equal(
    readLines(file.path(tmp, "tmp", "boo")),
    "boo"
  )
})
