
context("unzip")

test_that("can unzip all", {
  z <- make_a_zip()

  tmp2 <- test_temp_dir()
  zip::unzip(z$zip, exdir = tmp2)

  expect_true(file.exists(file.path(tmp2, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir", "file2")))

  expect_equal(readLines(file.path(tmp2, basename(z$ex), "file1")), "file1")
  expect_equal(
    readLines(file.path(tmp2, basename(z$ex), "dir", "file2")), "file2")
})

test_that("unzip creates exdir if needed", {
  z <- make_a_zip()

  tmp2 <- test_temp_dir(create = FALSE)
  expect_false(file.exists(tmp2))
  zip::unzip(z$zip, exdir = tmp2)

  expect_true(file.exists(tmp2))

  expect_true(file.exists(file.path(tmp2, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir", "file2")))

  expect_equal(readLines(file.path(tmp2, basename(z$ex), "file1")), "file1")
  expect_equal(
    readLines(file.path(tmp2, basename(z$ex), "dir", "file2")), "file2")
})

test_that("unzip certain files only", {
  z <- make_a_zip()

  ## No files
  tmp2 <- test_temp_dir()
  zip::unzip(z$zip, character(), exdir = tmp2)
  expect_true(file.exists(tmp2))
  expect_equal(dir(tmp2), character())

  ## File in directory
  tmp3 <- test_temp_dir()
  zip::unzip(z$zip, paste0(basename(z$ex), "/", "file1"), exdir = tmp3)
  expect_true(file.exists(tmp3))
  expect_true(file.exists(file.path(tmp3, basename(z$ex), "file1")))
  expect_false(file.exists(file.path(tmp3, basename(z$ex), "dir")))
  expect_equal(readLines(file.path(tmp3, basename(z$ex), "file1")), "file1")

  ## Only file(s) in root
  f <- test_temp_file()
  cat("foobar\n", file = f)
  zip <- test_temp_file(".zip")
  zipr(zip, f)

  tmp4 <- test_temp_dir()
  zip::unzip(zip, paste0(basename(f)), exdir = tmp4)
  expect_true(file.exists(tmp4))
  expect_equal(dir(tmp4), basename(f))
  expect_equal(readLines(file.path(tmp4, basename(f))), "foobar")

  ## Directory only
  tmp5 <- test_temp_dir()
  zip::unzip(z$zip, paste0(basename(z$ex), "/dir/"), exdir = tmp5)
  expect_true(file.exists(tmp5))
  expect_true(file.exists(file.path(tmp5, basename(z$ex), "dir")))

  ## Files and dirs
  tmp6 <- test_temp_dir()
  zip::unzip(z$zip, paste0(basename(z$ex), c("/dir/file2", "/file1")),
            exdir = tmp6)

  expect_true(file.exists(file.path(tmp6, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(tmp6, basename(z$ex), "dir")))
  expect_true(file.exists(file.path(tmp6, basename(z$ex), "dir", "file2")))

  expect_equal(readLines(file.path(tmp6, basename(z$ex), "file1")), "file1")
  expect_equal(
    readLines(file.path(tmp6, basename(z$ex), "dir", "file2")), "file2")
})

test_that("unzip sets mtime correctly", {
  ## ten minutes earlier
  mtime <- Sys.time() - 60 * 10
  z <- make_a_zip(mtime = mtime)

  ## Some Windows file systems have a 2-second precision
  three <- as.difftime(3, units = "secs")
  expect_true(all(abs(zip_list(z$zip)$timestamp - mtime) < 3))

  tmp2 <- test_temp_dir()
  zip::unzip(z$zip, exdir = tmp2)

  ok <- function(...) {
    t <- file.info(file.path(tmp2, basename(z$ex), ...))$mtime
    expect_true(abs(t - mtime) < 3)
  }

  ok("file1")
  ok("file11")
  ok("dir")
  ok("dir", "file2")
  ok("dir", "file3")
})

test_that("overwrite is FALSE", {
  z <- make_a_zip()
  tmp <- test_temp_dir()
  zip::unzip(z$zip, exdir = tmp)
  zip::unzip(z$zip, exdir = tmp)
  expect_error(
    zip::unzip(z$zip, overwrite = FALSE, exdir = tmp),
    "Not overwriting")
})

test_that("junkpaths is TRUE", {
  z <- make_a_zip()
  tmp <- test_temp_dir()
  zip::unzip(z$zip, exdir = tmp, junkpaths = TRUE)

  expect_true(file.exists(file.path(tmp, "file1")))
  expect_true(file.exists(file.path(tmp, "file2")))
  expect_true(file.exists(file.path(tmp, "file11")))
  expect_true(file.exists(file.path(tmp, "file3")))

  expect_false(file.exists(file.path(tmp, "dir")))

  expect_equal(readLines(file.path(tmp, "file1")), "file1")
  expect_equal(readLines(file.path(tmp, "file2")), "file2")
})

test_that("permissions as kept on Unix", {
  skip_on_os("windows")

  tmp <- test_temp_dir()
  Sys.chmod(tmp, "0777", FALSE)

  cat("foobar\n", file = f <- file.path(tmp, "file1"))
  Sys.chmod(f, "0400", FALSE)

  dir.create(f <- file.path(tmp, "dir"))
  Sys.chmod(f, "0700", FALSE)

  cat("foobar2\n", file = f <- file.path(tmp, "dir", "file2"))
  Sys.chmod(f, "0755",  FALSE)

  cat("foobar3\n", file = f <- file.path(tmp, "dir", "file3"))
  Sys.chmod(f, "0777",  FALSE)

  zip <- test_temp_file(".zip", create = FALSE)
  zipr(zip, tmp)

  tmp2 <- test_temp_dir()
  zip::unzip(zip, exdir = tmp2)

  check_perm <- function(mode, ...) {
    f <- file.path(tmp2, ...)
    expect_equal(file.info(f)$mode, as.octmode(mode))
  }

  check_perm("0777", basename(tmp))
  check_perm("0400", basename(tmp), "file1")
  check_perm("0700", basename(tmp), "dir")
  check_perm("0755", basename(tmp), "dir", "file2")
  check_perm("0777", basename(tmp), "dir", "file3")
})
