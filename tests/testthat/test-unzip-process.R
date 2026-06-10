test_that("unzip_process", {
  z <- make_a_zip()
  tmp2 <- test_temp_dir()
  p1 <- unzip_process()$new(z$zip, tmp2)
  p1$wait(2000)
  p1$kill()

  expect_equal(p1$get_exit_status(), 0)

  expect_true(file.exists(file.path(tmp2, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir", "file2")))

  expect_equal(readLines(file.path(tmp2, basename(z$ex), "file1")), "file1")
  expect_equal(
    readLines(file.path(tmp2, basename(z$ex), "dir", "file2")),
    "file2"
  )
})

test_that("unzip_process fallback via callr", {
  skip_if_not_installed("callr")

  z <- make_a_zip()
  tmp2 <- test_temp_dir()

  old_works <- zip_data$unzip_exe_works
  old_class <- zip_data$unzip_class
  zip_data$unzip_exe_works <- FALSE
  zip_data$unzip_class <- NULL
  on.exit(
    {
      zip_data$unzip_exe_works <- old_works
      zip_data$unzip_class <- old_class
    },
    add = TRUE
  )

  p1 <- unzip_process()$new(z$zip, tmp2)
  p1$wait(10000)

  expect_equal(p1$get_exit_status(), 0)

  expect_true(file.exists(file.path(tmp2, basename(z$ex), "file1")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir")))
  expect_true(file.exists(file.path(tmp2, basename(z$ex), "dir", "file2")))

  expect_equal(readLines(file.path(tmp2, basename(z$ex), "file1")), "file1")
  expect_equal(
    readLines(file.path(tmp2, basename(z$ex), "dir", "file2")),
    "file2"
  )
})
