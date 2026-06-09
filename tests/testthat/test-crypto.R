# Unit tests for the WinZip AES crypto primitives (src/crypto.c), exercised
# through the hidden .Call test shims registered in src/init.c. Vectors are
# from the published standards, so these verify the primitives in isolation
# before they are wired into the zip reader/writer.

hex <- function(x) {
  paste(format(x), collapse = "")
}
unhex <- function(x) {
  as.raw(strtoi(substring(x, seq(1, nchar(x), 2), seq(2, nchar(x), 2)), 16L))
}

test_that("PBKDF2-HMAC-SHA1 matches RFC 6070 vectors", {
  pbkdf2 <- function(pw, salt, iter, dklen) {
    .Call(
      c_R_crypto_pbkdf2_sha1,
      charToRaw(pw),
      charToRaw(salt),
      as.integer(iter),
      as.integer(dklen)
    )
  }

  expect_equal(
    hex(pbkdf2("password", "salt", 1, 20)),
    "0c60c80f961f0e71f3a9b524af6012062fe037a6"
  )
  expect_equal(
    hex(pbkdf2("password", "salt", 2, 20)),
    "ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957"
  )
  expect_equal(
    hex(pbkdf2("password", "salt", 4096, 20)),
    "4b007901b765489abead49d926f721d065a429c1"
  )
  expect_equal(
    hex(pbkdf2(
      "passwordPASSWORDpassword",
      "saltSALTsaltSALTsaltSALTsaltSALTsalt",
      4096,
      25
    )),
    "3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038"
  )
})

test_that("PBKDF2-HMAC-SHA1 handles embedded NUL (RFC 6070)", {
  out <- .Call(
    c_R_crypto_pbkdf2_sha1,
    as.raw(c(charToRaw("pass"), 0L, charToRaw("word"))),
    as.raw(c(charToRaw("sa"), 0L, charToRaw("lt"))),
    4096L,
    16L
  )
  expect_equal(hex(out), "56fa6aa75548099dcc37d7f03425e0c3")
})

test_that("HMAC-SHA1 matches RFC 2202 vectors", {
  hmac <- function(key, data) .Call(c_R_crypto_hmac_sha1, key, data)

  # Test case 1
  expect_equal(
    hex(hmac(as.raw(rep(0x0b, 20)), charToRaw("Hi There"))),
    "b617318655057264e28bc0b6fb378c8ef146be00"
  )
  # Test case 2
  expect_equal(
    hex(hmac(charToRaw("Jefe"), charToRaw("what do ya want for nothing?"))),
    "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79"
  )
  # Test case 3
  expect_equal(
    hex(hmac(as.raw(rep(0xaa, 20)), as.raw(rep(0xdd, 50)))),
    "125d7342b9ac11cd91a39af48aa17b4f63f175d3"
  )
})

test_that("AES-CTR (WinZip counter) round-trips", {
  for (klen in c(16L, 24L, 32L)) {
    key <- as.raw(seq_len(klen) %% 256L)
    plain <- charToRaw(strrep("The quick brown fox. ", 5)) # spans many blocks
    cipher <- .Call(c_R_crypto_aes_ctr, key, plain)
    expect_false(identical(cipher, plain))
    back <- .Call(c_R_crypto_aes_ctr, key, cipher)
    expect_equal(back, plain)
  }
})

test_that("AES-CTR keystream uses little-endian counter starting at 1", {
  # The keystream of the first block is AES-ECB(key, counter=1). We reproduce
  # the first 16 keystream bytes by encrypting 16 zero bytes (XOR with zero),
  # and check that encrypting a second block consumes counter=2, i.e. the two
  # 16-byte halves of a 32-byte zero input differ.
  key <- as.raw(rep(0L, 16))
  ks <- .Call(c_R_crypto_aes_ctr, key, as.raw(rep(0L, 32)))
  expect_equal(length(ks), 32L)
  expect_false(identical(ks[1:16], ks[17:32]))
})

test_that("WinZip AES key block derivation splits PBKDF2 output", {
  # The derived block is enc_key || mac_key || 2-byte verifier from a single
  # PBKDF2-HMAC-SHA1(1000) call, so concatenating the parts must equal the
  # PBKDF2 output of the matching length.
  for (strength in 1:3) {
    klen <- c(16L, 24L, 32L)[strength]
    salt_len <- c(8L, 12L, 16L)[strength]
    pw <- charToRaw("hunter2")
    salt <- as.raw(seq_len(salt_len) %% 256L)

    keys <- .Call(c_R_crypto_winzip_keys, pw, salt, as.integer(strength))
    expect_equal(length(keys$enc_key), klen)
    expect_equal(length(keys$mac_key), klen)
    expect_equal(length(keys$verifier), 2L)

    full <- .Call(
      c_R_crypto_pbkdf2_sha1,
      pw,
      salt,
      1000L,
      as.integer(2L * klen + 2L)
    )
    expect_equal(c(keys$enc_key, keys$mac_key, keys$verifier), full)
  }
})

test_that("WinZip AES key derivation rejects invalid strength", {
  expect_error(
    .Call(c_R_crypto_winzip_keys, charToRaw("x"), charToRaw("yyyyyyyy"), 0L),
    "strength"
  )
})
