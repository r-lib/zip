test_that("keys renames a single file", {
  tmp <- test_temp_dir()
  writeLines("hello", file.path(tmp, "orig.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, "orig.txt", keys = "renamed.txt")
  })

  expect_equal(zip_list(zipfile)$filename, "renamed.txt")

  out <- test_temp_dir()
  unzip(zipfile, exdir = out)
  expect_equal(readLines(file.path(out, "renamed.txt")), "hello")
})

test_that("keys renames a directory (mirror mode)", {
  tmp <- test_temp_dir()
  dir.create(file.path(tmp, "mydir"))
  cat("a", file = file.path(tmp, "mydir", "file1"))
  cat("b", file = file.path(tmp, "mydir", "file2"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, "mydir", keys = "newname")
  })

  expect_equal(
    zip_list(zipfile)$filename,
    c("newname/", "newname/file1", "newname/file2")
  )
})

test_that("keys renames a directory (cherry-pick mode)", {
  tmp <- test_temp_dir()
  dir.create(file.path(tmp, "mydir"))
  cat("a", file = file.path(tmp, "mydir", "file1"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, "mydir", mode = "cherry-pick", keys = "newname")
  })

  expect_equal(
    zip_list(zipfile)$filename,
    c("newname/", "newname/file1")
  )
})

test_that("keys works with mixed files and directories", {
  tmp <- test_temp_dir()
  dir.create(file.path(tmp, "d"))
  cat("x", file = file.path(tmp, "d", "f"))
  cat("y", file = file.path(tmp, "top.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, c("top.txt", "d"), keys = c("a.txt", "subdir"))
  })

  expect_equal(
    sort(zip_list(zipfile)$filename),
    sort(c("a.txt", "subdir/", "subdir/f"))
  )
})

test_that("keys errors when length mismatches files", {
  tmp <- test_temp_dir()
  cat("x", file = file.path(tmp, "f.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    expect_error(
      zip(zipfile, "f.txt", keys = c("a.txt", "b.txt")),
      "`keys` must have the same length"
    )
  })
})

test_that("keys warns and skips directories when recurse = FALSE", {
  tmp <- test_temp_dir()
  dir.create(file.path(tmp, "d"))
  cat("x\n", file = file.path(tmp, "d", "f"))
  cat("y\n", file = file.path(tmp, "top.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    expect_warning(
      zip(zipfile, c("top.txt", "d"), keys = c("a.txt", "subdir"), recurse = FALSE),
      "directories ignored"
    )
  })

  expect_equal(zip_list(zipfile)$filename, "a.txt")
})

test_that("keys with '.' in cherry-pick mode stores contents under key", {
  tmp <- test_temp_dir()
  cat("x\n", file = file.path(tmp, "f.txt"))
  dir.create(file.path(tmp, "sub"))
  cat("y\n", file = file.path(tmp, "sub", "g.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, ".", mode = "cherry-pick", keys = "mydir")
  })

  fns <- zip_list(zipfile)$filename
  expect_true("mydir/" %in% fns)
  expect_true("mydir/f.txt" %in% fns)
  expect_true("mydir/sub/" %in% fns)
  expect_true("mydir/sub/g.txt" %in% fns)
})

test_that("keys allows '.' in files in mirror mode", {
  tmp <- test_temp_dir()
  cat("x\n", file = file.path(tmp, "f.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, ".", keys = "mydir")
  })

  fns <- zip_list(zipfile)$filename
  expect_true("mydir/" %in% fns)
  expect_true("mydir/f.txt" %in% fns)
})

test_that("keys works with nested directories", {
  tmp <- test_temp_dir()
  dir.create(file.path(tmp, "a", "b"), recursive = TRUE)
  cat("deep", file = file.path(tmp, "a", "b", "file.txt"))
  zipfile <- test_temp_file(".zip", create = FALSE)

  withr::with_dir(tmp, {
    zip(zipfile, "a", keys = "x")
  })

  fns <- zip_list(zipfile)$filename
  expect_true("x/" %in% fns)
  expect_true("x/b/" %in% fns)
  expect_true("x/b/file.txt" %in% fns)
})
