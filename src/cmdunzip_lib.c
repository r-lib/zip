
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "zip.h"

static ZIP_THREAD_LOCAL char tl_error_msg[1024];

static void dll_error_handler(const char *reason, const char *file,
                               int line, int zip_errno, int eno) {
  (void) file; (void) line; (void) zip_errno; (void) eno;
  snprintf(tl_error_msg, sizeof(tl_error_msg), "%s", reason);
  /* return normally; ZIP_ERROR macro executes `return 1` next */
}

static int hex_nibble(unsigned int c) {
  if (c >= '0' && c <= '9') return (int)(c - '0');
  if (c >= 'a' && c <= 'f') return (int)(c - 'a') + 10;
  if (c >= 'A' && c <= 'F') return (int)(c - 'A') + 10;
  return -1;
}

static int decode_hex_password(const char *hex, unsigned char **out) {
  size_t hlen = strlen(hex);
  if (hlen % 2 != 0) return -1;
  size_t outlen = hlen / 2;
  *out = (unsigned char *) malloc(outlen + 1);
  if (!*out) return -1;
  for (size_t i = 0; i < outlen; i++) {
    int hi = hex_nibble((unsigned int) hex[2 * i]);
    int lo = hex_nibble((unsigned int) hex[2 * i + 1]);
    if (hi < 0 || lo < 0) { free(*out); return -1; }
    (*out)[i] = (unsigned char)((hi << 4) | lo);
  }
  return (int) outlen;
}

/*
 * Unzip zipfile into exdir. hex_password may be NULL or empty string.
 * All paths are UTF-8. Returns 0 on success, non-zero on failure.
 * On failure, error_buf is filled with a null-terminated message.
 */
#if defined(__GNUC__) || defined(__clang__)
__attribute__((visibility("default")))
#endif
int do_cmdunzip(const char *zipfile, const char *exdir,
                const char *hex_password,
                char *error_buf, size_t error_buf_len) {
  zip_set_error_handler(dll_error_handler);
  tl_error_msg[0] = '\0';

  unsigned char *password = NULL;
  int password_len = 0;
  if (hex_password && hex_password[0]) {
    password_len = decode_hex_password(hex_password, &password);
    if (password_len < 0) {
      snprintf(error_buf, error_buf_len, "Invalid hex password");
      return 1;
    }
  }

  int ret = zip_unzip(zipfile, /* cfiles= */ NULL, /* num_files= */ 0,
                      /* coverwrite= */ 1, /* cjunkpaths= */ 0,
                      /* exdir= */ exdir,
                      /* decode_fn= */ NULL, /* decode_data= */ NULL,
                      /* entry_fn= */ NULL, /* entry_data= */ NULL,
                      password, (size_t) password_len);
  free(password);

  if (ret != 0 && error_buf && error_buf_len > 0) {
    snprintf(error_buf, error_buf_len, "%s",
             tl_error_msg[0] ? tl_error_msg : "unknown error");
  }
  return ret;
}
