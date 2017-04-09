
context("zip")

test_that("can compress single directory", {

  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))

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
})

test_that("can compress single file", {

  on.exit(try(unlink(c(zipfile, tmp), recursive = TRUE)))
  
  tmp <- tempfile()
  cat("compress this if you can!", file = tmp)

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip(zipfile, basename(tmp))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(basename(list$filename), basename(tmp))
})

test_that("can compress multiple files", {

  on.exit(try(unlink(c(zipfile, tmp1, tmp2), recursive = TRUE)))
  
  cat("compress this if you can!", file = tmp1 <- tempfile())
  cat("or even this one", file = tmp2 <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp1),
      zip(zipfile, basename(c(tmp1, tmp2)))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(basename(list$filename), basename(c(tmp1, tmp2)))
})

test_that("can compress multiple directories", {

  on.exit(try(unlink(c(zipfile, tmp1, tmp2), recursive = TRUE)))

  dir.create(tmp1 <- tempfile())
  dir.create(tmp2 <- tempfile())
  cat("first file", file = file.path(tmp1, "file1"))
  cat("second file", file = file.path(tmp1, "file2"))
  cat("third file", file = file.path(tmp2, "file3"))
  cat("fourth file", file = file.path(tmp2, "file4"))

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp1),
      zip(zipfile, basename(c(tmp1, tmp2)))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c("file1", "file2", "file3", "file4")
  )
})

test_that("can compress files and directories", {

  on.exit(try(unlink(c(zipfile, tmp, file1, file2), recursive = TRUE)))

  dir.create(tmp <- tempfile())
  cat("first file", file = file.path(tmp, "file1"))
  cat("second file", file = file.path(tmp, "file2"))
  cat("third file", file = file1 <- tempfile())
  cat("fourth file", file = file2 <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip(zipfile, basename(c(file1, tmp, file2)))
    )
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c(basename(file1), "file1", "file2", basename(file2))
  )
})

test_that("warning for directories in non-recursive mode", {

  on.exit(try(unlink(c(zipfile, tmp, file1, file2), recursive = TRUE)))

  dir.create(tmp <- tempfile())
  cat("first file", file = file.path(tmp, "file1"))
  cat("second file", file = file.path(tmp, "file2"))
  cat("third file", file = file1 <- tempfile())
  cat("fourth file", file = file2 <- tempfile())

  zipfile <- tempfile(fileext = ".zip")

  expect_warning(
    withr::with_dir(
      dirname(tmp),
      zip(zipfile, basename(c(file1, tmp, file2)), recurse = FALSE)
    ),
    "directories ignored"
  )

  expect_true(file.exists(zipfile))

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c(basename(file1), basename(file2))
  )
})

test_that("compression level is used", {

  on.exit(try(unlink(c(zipfile1, zipfile2, file), recursive = TRUE)))
  
  tmp <- tempfile()
  write(1:10000, file = file <- tempfile())

  zipfile1 <- tempfile(fileext = ".zip")
  zipfile2 <- tempfile(fileext = ".zip")

  expect_silent(
    withr::with_dir(
      dirname(file),
      zip(zipfile1, basename(file), compression_level = 1)
    )
  )

  expect_silent(
    withr::with_dir(
      dirname(file),
      zip(zipfile2, basename(file), compression_level = 9)
    )
  )
  
  expect_true(file.exists(zipfile1))
  expect_true(file.exists(zipfile2))

  list <- zip_list(zipfile1)
  expect_equal(basename(list$filename), basename(file))

  list <- zip_list(zipfile2)
  expect_equal(basename(list$filename), basename(file))

  expect_true(file.info(zipfile1)$size <= file.info(zipfile2)$size)
})

test_that("can append a directory to an archive", {

  on.exit(try(unlink(c(zipfile, tmp, tmp2), recursive = TRUE)))

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

  dir.create(tmp2 <- tempfile())
  cat("first file2", file = file.path(tmp2, "file3"))
  cat("second file2", file = file.path(tmp2, "file4"))

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip_append(zipfile, basename(tmp2))
    )
  )

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c("file1", "file2", "file3", "file4")
  )  
})

test_that("can append a file to an archive", {

  on.exit(try(unlink(c(zipfile, tmp, file1), recursive = TRUE)))

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

  cat("first file2", file = file1 <- tempfile())

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip_append(zipfile, basename(file1))
    )
  )

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c("file1", "file2", basename(file1))
  )  
})

test_that("can append files and directories to an archive", {

  on.exit(try(unlink(c(zipfile, tmp, tmp2, file1), recursive = TRUE)))

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

  cat("first file2", file = file1 <- tempfile())
  dir.create(tmp2 <- tempfile())
  cat("another", file = file.path(tmp2, "file3"))
  cat("and another", file = file.path(tmp2, "file4"))

  expect_silent(
    withr::with_dir(
      dirname(tmp),
      zip_append(zipfile, basename(c(file1, tmp2)))
    )
  )

  list <- zip_list(zipfile)
  expect_equal(
    basename(list$filename),
    c("file1", "file2", basename(file1), "file3", "file4")
  )  
})
