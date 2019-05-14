
context("zip_process")

test_that("zip_process", {
  z <- make_a_zip()

  zip2 <- test_temp_file(".zip")
  p <- zip_process()$new(zip2, z$ex)
  p$wait(2000)
  p$kill()

  expect_equal(p$get_exit_status(), 0L)
  expect_equal(zip_list(z$zip), zip_list(zip2))
})

test_that("can omit directories", {
  z <- make_a_zip(include_directories = FALSE)

  zip2 <- test_temp_file(".zip")
  p <- zip_process()$new(zip2, z$ex, include_directories = FALSE)
  p$wait(2000)
  p$kill()

  expect_equal(p$get_exit_status(), 0L)
  expect_equal(zip_list(z$zip), zip_list(zip2))
})
