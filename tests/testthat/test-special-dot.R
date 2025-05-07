test_that("`.` is special in cherry picking mode", {
  dir.create(tmp <- tempfile("zip-test-dot-"))
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(tmp)

  dir.create("xxx")
  writeLines("bar", file.path("xxx", "bar"))
  writeLines("foo", file.path("xxx", "foo"))
  setwd("xxx")

  zip::zip("../out.zip", ".", mode = "cherry-pick", include_directories = FALSE)

  expect_equal(sort(zip_list("../out.zip")$file), sort(c("bar", "foo")))
})
