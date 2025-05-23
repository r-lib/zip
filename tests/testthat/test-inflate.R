test_that("inflate", {
  data_gz <- as.raw(c(
    0x78,
    0x9c,
    0xa5,
    0xcc,
    0x4d,
    0x0a,
    0x83,
    0x30,
    0x10,
    0x40,
    0xe1,
    0x7d,
    0x4e,
    0x31,
    0xfb,
    0x82,
    0x4c,
    0xfe,
    0x34,
    0x42,
    0x29,
    0xa5,
    0x2e,
    0xba,
    0xef,
    0x0d,
    0xc6,
    0x64,
    0x62,
    0x85,
    0x46,
    0x25,
    0xc6,
    0xde,
    0xc7,
    0xb3,
    0x78,
    0xb1,
    0x7a,
    0x87,
    0xae,
    0x1e,
    0x7c,
    0x8b,
    0x57,
    0x32,
    0x33,
    0x38,
    0x6e,
    0x94,
    0x37,
    0x9e,
    0x6a,
    0xe7,
    0xb1,
    0xb5,
    0x68,
    0x75,
    0xaf,
    0xbc,
    0x0a,
    0x3d,
    0xa3,
    0x8b,
    0x8d,
    0x6a,
    0x49,
    0x6b,
    0xa4,
    0x28,
    0x23,
    0x93,
    0x58,
    0x28,
    0xf3,
    0x54,
    0x20,
    0x44,
    0x43,
    0xca,
    0xd5,
    0xc6,
    0xb4,
    0x88,
    0x36,
    0x78,
    0xe4,
    0x68,
    0x0d,
    0x73,
    0x4d,
    0xec,
    0x90,
    0x42,
    0xb4,
    0x51,
    0x9a,
    0x80,
    0xec,
    0x83,
    0x16,
    0xb4,
    0x95,
    0xf7,
    0x9c,
    0xe1,
    0x79,
    0xec,
    0xfd,
    0x99,
    0x6e,
    0x3d,
    0xf6,
    0x1c,
    0x46,
    0xb8,
    0xfa,
    0x95,
    0xce,
    0x56,
    0x03,
    0x9d,
    0x7a,
    0x1f,
    0x12,
    0x8d,
    0x9f,
    0xca,
    0xcf,
    0xe9,
    0x06,
    0xb2,
    0x6e,
    0xa4,
    0x6a,
    0x14,
    0x6a,
    0x84,
    0x0b,
    0x4a,
    0x44,
    0x71,
    0x6a,
    0x1a,
    0x4b,
    0xe1,
    0x3f,
    0x16,
    0xe2,
    0xb1,
    0xa5,
    0x05,
    0xca,
    0x0c,
    0xaf,
    0x0e,
    0xbe,
    0x9c,
    0xd7,
    0x71,
    0x9e,
    0xc4,
    0x0f,
    0x2b,
    0x30,
    0x4d,
    0xe3,
    0xa0,
    0x31,
    0x78,
    0x9c,
    0x33,
    0x34,
    0x30,
    0x30,
    0x33,
    0x31,
    0x51,
    0xd0,
    0x0b,
    0x4a,
    0x2a,
    0xcd,
    0xcc,
    0x49,
    0xc9,
    0x4c,
    0xcf,
    0xcb,
    0x2f,
    0x4a,
    0x65,
    0xa8,
    0x48,
    0xae,
    0x29,
    0x77,
    0xfc,
    0x78,
    0x21
  ))

  data <- inflate(data_gz, 1L, 245L)
  out <- rawToChar(data$output)
  Encoding(out) <- "UTF-8"
  if (l10n_info()[["UTF-8"]]) {
    variant <- "utf8"
  } else {
    out <- iconv(out, "UTF-8", "ASCII", sub = "byte")
    variant <- "ascii"
  }
  expect_snapshot(
    cat(out),
    variant = variant
  )

  # buffer is resized
  expect_silent(inflate(data_gz, 1L, 200L))

  # bad format
  expect_snapshot(error = TRUE, inflate(data_gz, 10L, 300L))
})

test_that("deflate", {
  data_gz <- deflate(charToRaw("Hello world!"))
  data <- inflate(data_gz$output)
  expect_equal(data_gz$bytes_written, data$bytes_read)
  expect_equal(data_gz$bytes_read, data$bytes_written)
  expect_snapshot(rawToChar(data$output))

  # output is resized
  data_gz_2 <- deflate(charToRaw("Hello world!"), size = 5)
  expect_equal(data_gz, data_gz_2)
  data_gz_3 <- deflate(charToRaw("Hello world!"), size = 500)
  expect_equal(data_gz, data_gz_3)
})
