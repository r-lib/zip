test_that("is_true_env_var", {
  withr::local_envvar(ZIP_TEST_ENV = NA)
  expect_null(is_true_env_var("ZIP_TEST_ENV"))

  for (val in c("true", "TRUE", "True", "on", "yes", "1", "Y")) {
    withr::local_envvar(ZIP_TEST_ENV = val)
    expect_true(is_true_env_var("ZIP_TEST_ENV"), info = val)
  }

  for (val in c("false", "FALSE", "False", "off", "no", "0", "N")) {
    withr::local_envvar(ZIP_TEST_ENV = val)
    expect_false(is_true_env_var("ZIP_TEST_ENV"), info = val)
  }

  withr::local_envvar(ZIP_TEST_ENV = "maybe")
  expect_error(is_true_env_var("ZIP_TEST_ENV"))
})
