/* WinZip AES crypto primitives, built on the vendored Mbed TLS subset.
   See PASSWORD-SUPPORT-PLAN.md (step 1) and src/mbedtls/VENDORING.md.

   This file is intentionally free of any R dependency so it can be linked
   into the standalone cmdzip/cmdunzip tools as well as the R shared library.
   The R-callable test shims live in rzip.c. */

#include <string.h>

#include "mbedtls/aes.h"
#include "mbedtls/md.h"
#include "mbedtls/pkcs5.h"

#include "crypto.h"

#define WINZIP_AES_BLOCK_SIZE 16
#define WINZIP_KEYING_ITERATIONS 1000
#define WINZIP_PWD_VERIFIER_LEN 2

int zip_winzip_key_len(int strength) {
  switch (strength) {
    case 1: return 16;
    case 2: return 24;
    case 3: return 32;
    default: return -1;
  }
}

int zip_winzip_salt_len(int strength) {
  switch (strength) {
    case 1: return 8;
    case 2: return 12;
    case 3: return 16;
    default: return -1;
  }
}

int zip_aes_ctr_crypt(const unsigned char *key, int keybits,
                      const unsigned char *in, unsigned char *out, size_t len) {
  mbedtls_aes_context aes;
  unsigned char ctr[WINZIP_AES_BLOCK_SIZE];
  unsigned char ks[WINZIP_AES_BLOCK_SIZE];
  size_t i;
  int pos = WINZIP_AES_BLOCK_SIZE; /* force keystream generation on first byte */
  int ret;

  mbedtls_aes_init(&aes);
  ret = mbedtls_aes_setkey_enc(&aes, key, (unsigned int) keybits);
  if (ret != 0) {
    mbedtls_aes_free(&aes);
    return ret;
  }

  memset(ctr, 0, sizeof(ctr));
  for (i = 0; i < len; i++) {
    if (pos == WINZIP_AES_BLOCK_SIZE) {
      /* increment the 128-bit little-endian counter, with carry */
      int j = 0;
      while (j < WINZIP_AES_BLOCK_SIZE) {
        if (++ctr[j] != 0) break;
        j++;
      }
      ret = mbedtls_aes_crypt_ecb(&aes, MBEDTLS_AES_ENCRYPT, ctr, ks);
      if (ret != 0) {
        mbedtls_aes_free(&aes);
        return ret;
      }
      pos = 0;
    }
    out[i] = in[i] ^ ks[pos++];
  }

  mbedtls_aes_free(&aes);
  return 0;
}

int zip_pbkdf2_sha1(const unsigned char *pw, size_t pwlen,
                    const unsigned char *salt, size_t saltlen,
                    unsigned int iterations, unsigned char *out, size_t dklen) {
  return mbedtls_pkcs5_pbkdf2_hmac_ext(
    MBEDTLS_MD_SHA1, pw, pwlen, salt, saltlen,
    iterations, (uint32_t) dklen, out
  );
}

int zip_hmac_sha1(const unsigned char *key, size_t keylen,
                  const unsigned char *data, size_t datalen,
                  unsigned char out[20]) {
  const mbedtls_md_info_t *info = mbedtls_md_info_from_type(MBEDTLS_MD_SHA1);
  if (info == NULL) return -1;
  return mbedtls_md_hmac(info, key, keylen, data, datalen, out);
}

int zip_winzip_aes_keys(const unsigned char *pw, size_t pwlen,
                        const unsigned char *salt, size_t saltlen,
                        int strength,
                        unsigned char *enc_key,
                        unsigned char *mac_key,
                        unsigned char verifier[2]) {
  unsigned char block[32 + 32 + WINZIP_PWD_VERIFIER_LEN];
  int keylen = zip_winzip_key_len(strength);
  size_t total;
  int ret;

  if (keylen < 0) return -1;
  total = (size_t) keylen * 2 + WINZIP_PWD_VERIFIER_LEN;

  ret = zip_pbkdf2_sha1(pw, pwlen, salt, saltlen,
                        WINZIP_KEYING_ITERATIONS, block, total);
  if (ret != 0) return ret;

  memcpy(enc_key, block, (size_t) keylen);
  memcpy(mac_key, block + keylen, (size_t) keylen);
  memcpy(verifier, block + 2 * keylen, WINZIP_PWD_VERIFIER_LEN);

  return 0;
}
