
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <stdarg.h>
#include <stdio.h>

#ifdef _WIN32
#include <direct.h>		/* _mkdir */
#include <windows.h>
#else
#include <unistd.h>
#include <limits.h>
#endif

#include "miniz.h"
#include "zip.h"
#include "crypto.h"

/* ZIP spec: when bit 11 of general purpose bit flag is not set, filenames
   are encoded in IBM CP437. These are the Unicode codepoints for CP437
   bytes 0x80-0xFF. */
static const unsigned int cp437_unicode[128] = {
  0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
  0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
  0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
  0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
  0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
  0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
  0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
  0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
  0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
  0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
  0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
  0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
  0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4,
  0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
  0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248,
  0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0
};

/* Convert a CP437-encoded filename to a newly allocated UTF-8 string.
   Returns NULL on allocation failure. */
char *zip_cp437_to_utf8(const char *src) {
  const unsigned char *s = (const unsigned char *) src;
  size_t len = strlen(src);
  char *result = malloc(len * 3 + 1);
  if (!result) return NULL;
  char *p = result;
  size_t i;
  for (i = 0; i < len; i++) {
    unsigned char c = s[i];
    if (c < 0x80) {
      *p++ = (char) c;
    } else {
      unsigned int u = cp437_unicode[c - 0x80];
      if (u < 0x800) {
        *p++ = (char) (0xC0 | (u >> 6));
        *p++ = (char) (0x80 | (u & 0x3F));
      } else {
        *p++ = (char) (0xE0 | (u >> 12));
        *p++ = (char) (0x80 | ((u >> 6) & 0x3F));
        *p++ = (char) (0x80 | (u & 0x3F));
      }
    }
  }
  *p = '\0';
  return result;
}


#define ZIP_ERROR_BUFFER_SIZE 1000
static char zip_error_buffer[ZIP_ERROR_BUFFER_SIZE];

static const char *zip_error_strings[] = {
  /* 0 R_ZIP_ESUCCESS     */ "Success",
  /* 1 R_ZIP_EOPEN        */ "Cannot open zip file `%s` for reading",
  /* 2 R_ZIP_ENOMEM       */ "Cannot extract zip file `%s`, out of memory",
  /* 3 R_ZIP_ENOENTRY     */ "Cannot find file `%s` in zip archive `%s`",
  /* 4 R_ZIP_EBROKEN      */ "Cannot extract zip archive `%s`",
  /* 5 R_ZIP_EBROKENENTRY */ "Cannot extract entry `%s` from archive `%s`",
  /* 6 R_ZIP_EOVERWRITE   */ "Not overwriting `%s` when extracting `%s`",
  /* 7 R_ZIP_ECREATEDIR   */
     "Cannot create directory `%s` to extract `%s` from arghive `%s`",
  /* 8 R_ZIP_ESETPERM     */
     "Cannot set permissions for `%s` from archive `%s`",
  /* 9 R_ZIP_ESETMTIME    */
      "Failed to set mtime on `%s` while extracting `%s`",
  /*10 R_ZIP_EOPENWRITE   */ "Cannot open zip file `%s` for writing",
  /*11 R_ZIP_EOPENWRITE   */ "Cannot open zip file `%s` for appending",
  /*12 R_ZIP_EADDDIR      */ "Cannot add directory `%s` to archive `%s`",
  /*13 R_ZIP_EADDFILE     */ "Cannot add file `%s` to archive `%s`",
  /*14 R_ZIP_ESETZIPPERM  */
      "Cannot set permission on file `%s` in archive `%s`",
  /*15 R_ZIP_ECREATE      */ "Could not create zip archive `%s`",
  /*16 R_ZIP_EOPENX       */ "Cannot extract file `%s`",
  /*17 R_ZIP_FILESIZE     */ "Cannot determine size of `%s`",
  /*18 R_ZIP_ECREATELINK  */ "Cannot create symlink `%s` in archive `%s`",
  /*19 R_ZIP_EENCRYPT     */ "Cannot encrypt file `%s` in archive `%s`"
};

static zip_error_handler_t *zip_error_handler = 0;

void zip_set_error_handler(zip_error_handler_t *handler) {
  zip_error_handler = handler;
}

void zip_error(int errorcode, const char *file, int line, ...) {
  va_list va;
  int err = errno;
  va_start(va, line);
  vsnprintf(zip_error_buffer, ZIP_ERROR_BUFFER_SIZE - 1,
	    zip_error_strings[errorcode], va);
  zip_error_handler(zip_error_buffer, file, line, errorcode, err);
}

#define ZIP_ERROR(c, ...) do {				\
  zip_error((c), __FILE__, __LINE__, __VA_ARGS__);	\
  return 1; }  while(0)

void zip_error_mz(int errorcode, const char *mz_msg,
                  const char *file, int line, ...) {
  va_list va;
  int err = errno;
  va_start(va, line);
  int n = vsnprintf(zip_error_buffer, ZIP_ERROR_BUFFER_SIZE,
                    zip_error_strings[errorcode], va);
  va_end(va);
  if (n > 0 && n < ZIP_ERROR_BUFFER_SIZE - 1 &&
      mz_msg && mz_msg[0] && strcmp(mz_msg, "no error") != 0)
    snprintf(zip_error_buffer + n, ZIP_ERROR_BUFFER_SIZE - n, ": %s", mz_msg);
  zip_error_handler(zip_error_buffer, file, line, errorcode, err);
}

#define ZIP_ERROR_MZ(c, mz_errmsg, ...) do {                        \
  zip_error_mz((c), (mz_errmsg), __FILE__, __LINE__, __VA_ARGS__);  \
  return 1; } while(0)

int zip_set_permissions(mz_zip_archive *zip_archive, mz_uint file_index,
			const char *filename) {

  /* We only do this on Unix currently*/
#ifdef _WIN32
  return 0;
#else
  mz_uint16 version_by;
  mz_uint32 external_attr;
  struct stat st;

  if (! mz_zip_get_version_made_by(zip_archive, file_index, &version_by) ||
      ! mz_zip_get_external_attr(zip_archive, file_index, &external_attr)) {
    return 1;
  }

  if (stat(filename, &st)) return 1;

  version_by &= 0x00FF;
  version_by |= 3 << 8;

  /* We need to set the created-by version here, apparently, otherwise
     miniz will not set it properly.... */
  version_by |= 23;

  external_attr &= 0x0000FFFF;
  external_attr |= (st.st_mode & 0777) << 16;

  if (! mz_zip_set_version_made_by(zip_archive, file_index, version_by) ||
      ! mz_zip_set_external_attr(zip_archive, file_index, external_attr)) {
    return 1;
  }

  return 0;
#endif
}

/* Permissions are decoded from the archive bytes, not the host filesystem, so
   this is platform-independent: a ZIP made on Unix reports its stored mode the
   same way everywhere (and matches the R-based HTTP reader in R/http.R). For
   archives that carry no Unix permissions (not made by Unix, or a zero
   permission field, e.g. anything zipped on Windows) we fall back to a
   sensible default. */
int zip_get_permissions(mz_zip_archive_file_stat *stat, mode_t *mode) {
  mz_uint16 version_by = (stat->m_version_made_by >> 8) & 0xFF;
  mz_uint32 external_attr = (stat->m_external_attr >> 16) & 0xFFFF;

  /* If it is not made by Unix, or the permission field is zero,
     we ignore them. */
  if (version_by != 3 || external_attr == 0) {
    *mode = stat->m_is_directory ? 0700 : 0600;
    return 1;
  } else {
    *mode = (mode_t) external_attr & 0777;
  }

  return 0;
}

int zip_unzip(const char *czipfile, const char **cfiles, int num_files,
	      int coverwrite, int cjunkpaths, const char *cexdir,
	      zip_decode_fn decode_fn, void *decode_data,
	      zip_entry_fn entry_fn, void *entry_data) {

  int allfiles = cfiles == NULL;
  int i, n;
  mz_zip_archive zip_archive;
  memset(&zip_archive, 0, sizeof(zip_archive));

  zip_char_t *buffer = NULL;
  size_t buffer_size = 0;

  FILE *zfh = zip_open_utf8(czipfile, ZIP__READ, &buffer, &buffer_size);
  if (zfh == NULL) ZIP_ERROR(R_ZIP_EOPEN, czipfile);
  if (!mz_zip_reader_init_cfile(&zip_archive, zfh, 0, 0)) {
    const char *mz_err =
      mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
    if (buffer) free(buffer);
    fclose(zfh);
    ZIP_ERROR_MZ(R_ZIP_EOPEN, mz_err, czipfile);
  }

  n = allfiles ? mz_zip_reader_get_num_files(&zip_archive) : num_files;

  char *key_utf8 = NULL;

  for (i = 0; i < n; i++) {
    if (key_utf8) { free(key_utf8); key_utf8 = NULL; }
    mz_uint32 idx = -1;
    const char *key = 0;
    mz_zip_archive_file_stat file_stat;

    if (allfiles) {
      idx = (mz_uint32) i;
    } else {
      key = cfiles[i];
      if (!mz_zip_reader_locate_file_v2(&zip_archive, key, /* pComment= */ 0,
				       /* flags= */ 0, &idx)) {
	      const char *mz_err =
	        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR_MZ(R_ZIP_ENOENTRY, mz_err, key, czipfile);
      }
    }

    if (! mz_zip_reader_file_stat(&zip_archive, idx, &file_stat)) {
      const char *mz_err =
        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      fclose(zfh);
      ZIP_ERROR_MZ(R_ZIP_EBROKEN, mz_err, czipfile);
    }
    key = file_stat.m_filename;
    /* key_for_fs is the UTF-8 version of key used for filesystem operations.
       key always points to file_stat.m_filename for use in error messages. */
    if (!(file_stat.m_bit_flag & 0x800)) {
      key_utf8 = decode_fn ? decode_fn(key, decode_data) : zip_cp437_to_utf8(key);
      if (!key_utf8) {
        mz_zip_reader_end(&zip_archive);
        if (buffer) free(buffer);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
      }
    }
    const char *key_for_fs = key_utf8 ? key_utf8 : key;

    if (zip_str_file_path(cexdir, key_for_fs, &buffer, &buffer_size, cjunkpaths)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      fclose(zfh);
      ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
    }
#ifndef WIN32
    mz_uint32 attr = file_stat.m_external_attr >> 16;
#endif

    if (file_stat.m_is_directory) {
      if (! cjunkpaths && zip_mkdirp(buffer, 1)) {
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR(R_ZIP_EBROKENENTRY, key, czipfile);
      }

#ifndef WIN32
    } else if (S_ISLNK(attr)) {
      if (file_stat.m_uncomp_size >= PATH_MAX) {
        mz_zip_reader_end(&zip_archive);
        if (buffer) free(buffer);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_EBROKENENTRY, key, czipfile);
      }
      char *tmpbuf = malloc(file_stat.m_uncomp_size + 1);
      if (!tmpbuf) {
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR(R_ZIP_ENOMEM, key, czipfile);
      }

      if (!mz_zip_reader_extract_to_mem(
        &zip_archive,
        idx,
        tmpbuf,
        file_stat.m_uncomp_size,
        0
      )) {
        const char *mz_err =
          mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
        free(tmpbuf);
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR_MZ(R_ZIP_EBROKENENTRY, mz_err, key, czipfile);
      }
      tmpbuf[file_stat.m_uncomp_size] = '\0';
      if (symlink(tmpbuf, buffer)) {
        free(tmpbuf);
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR(R_ZIP_ECREATELINK, key, czipfile);
      }
      free(tmpbuf);

#endif

    } else {
      if (!coverwrite && zip_file_exists(buffer)) {
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR(R_ZIP_EOVERWRITE, key, czipfile);
      }

      if (! cjunkpaths && zip_mkdirp(buffer, 0)) {
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(zfh);
	      ZIP_ERROR(R_ZIP_ECREATEDIR, key, czipfile);
      }

      FILE *fh = NULL;
#ifdef _WIN32
      fh = _wfopen(buffer, L"wb");
#else
      fh = fopen(buffer, "wb");
#endif
      if (fh == NULL) {
        mz_zip_reader_end(&zip_archive);
        if (buffer) free(buffer);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_EOPENX, key);
      }

      if (!mz_zip_reader_extract_to_cfile(&zip_archive, idx, fh, 0)) {
	      const char *mz_err =
	        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
	      mz_zip_reader_end(&zip_archive);
	      if (buffer) free(buffer);
	      fclose(fh);
	      fclose(zfh);
	      ZIP_ERROR_MZ(R_ZIP_EBROKENENTRY, mz_err, key, czipfile);
      }
      fclose(fh);
    }
#ifndef _WIN32
    mode_t mode;
    /* returns 1 if there are no permissions. In that case we don't call
       call chmod() and leave the permissions as they are, the file was
       created with the default umask. */
    int ret = zip_get_permissions(&file_stat, &mode);
    if (!ret) {
      if (chmod(buffer, mode)) {
        mz_zip_reader_end(&zip_archive);
        if (buffer) free(buffer);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_ESETPERM, key, czipfile);
      }
    }
#endif
    if (entry_fn) entry_fn(n, i, &file_stat, key_for_fs, buffer, entry_data);
  }

  if (key_utf8) { free(key_utf8); key_utf8 = NULL; }

  /* Round two, to set the mtime on directories. We skip handling most
     of the errors here, because the central directory is unchanged, and
     if we got here, then it must be still good. */

  for (i = 0; ! cjunkpaths &&  i < n; i++) {
    mz_uint32 idx = -1;
    const char *key = 0;
    mz_zip_archive_file_stat file_stat;

    if (allfiles) {
      idx = (mz_uint32) i;
    } else {
      key = cfiles[i];
      mz_zip_reader_locate_file_v2(&zip_archive, key, /* pComment= */ 0,
				   /* flags= */ 0, &idx);
    }

    mz_zip_reader_file_stat(&zip_archive, idx, &file_stat);
    key = file_stat.m_filename;
    char *key_utf8_2 = NULL;
    if (!(file_stat.m_bit_flag & 0x800)) {
      key_utf8_2 = decode_fn ? decode_fn(key, decode_data) : zip_cp437_to_utf8(key);
    }
    const char *key_for_fs2 = key_utf8_2 ? key_utf8_2 : key;

    zip_str_file_path(cexdir, key_for_fs2, &buffer, &buffer_size, cjunkpaths);
    if (zip_set_mtime(buffer, file_stat.m_time)) {
      if (key_utf8_2) free(key_utf8_2);
      if (buffer) free(buffer);
      mz_zip_reader_end(&zip_archive);
      fclose(zfh);
      ZIP_ERROR(R_ZIP_ESETMTIME, key, czipfile);
    }
    if (key_utf8_2) free(key_utf8_2);
  }

  if (buffer) free(buffer);
  mz_zip_reader_end(&zip_archive);
  fclose(zfh);

  return 0;
}

static int zip_rename(const char *from, const char *to) {
#ifdef _WIN32
  wchar_t *wfrom = NULL, *wto = NULL;
  size_t wfrom_len = 0, wto_len = 0;
  int ret;
  if (zip__utf8_to_utf16(from, &wfrom, &wfrom_len) ||
      zip__utf8_to_utf16(to, &wto, &wto_len)) {
    if (wfrom) free(wfrom);
    if (wto) free(wto);
    return 1;
  }
  ret = MoveFileExW(wfrom, wto, MOVEFILE_REPLACE_EXISTING) ? 0 : 1;
  free(wfrom);
  free(wto);
  return ret;
#else
  return rename(from, to);
#endif
}

static void zip_remove_file(const char *path) {
#ifdef _WIN32
  wchar_t *wpath = NULL;
  size_t wpath_len = 0;
  if (!zip__utf8_to_utf16(path, &wpath, &wpath_len)) {
    DeleteFileW(wpath);
    free(wpath);
  }
#else
  remove(path);
#endif
}

typedef struct {
  FILE *fh;
  mz_uint64 *bytes_done_ptr;
  zip_progress_fn progress_fn;
  void *progress_data;
} zip_read_ctx_t;

static size_t zip_read_with_progress(void *pOpaque, mz_uint64 file_ofs,
                                     void *pBuf, size_t n) {
  (void) file_ofs;
  zip_read_ctx_t *ctx = (zip_read_ctx_t *) pOpaque;
  size_t ret = fread(pBuf, 1, n, ctx->fh);
  if (ret > 0 && ctx->progress_fn) {
    *ctx->bytes_done_ptr += (mz_uint64) ret;
    ctx->progress_fn(*ctx->bytes_done_ptr, ctx->progress_data);
  }
  return ret;
}

/* WinZip AES constants. We emit AE-2 (vendor version 2), which stores the
   CRC-32 as 0 and relies on the HMAC-SHA1 authentication code for integrity. */
#define ZIP_AES_VENDOR_VERSION 2
#define ZIP_AES_AUTHCODE_LEN   10
#define ZIP_WINZIP_METHOD      99
#define ZIP_WINZIP_EXTRA_LEN   11

/* Build the WinZip AES "0x9901" extra field (11 bytes). `real_method` is the
   compression method actually used for the data (0 = stored, 8 = deflated). */
static void zip_winzip_extra_field(unsigned char out[ZIP_WINZIP_EXTRA_LEN],
                                   int strength, int real_method) {
  out[0]  = 0x01; out[1] = 0x99;                       /* header id 0x9901 (LE) */
  out[2]  = 0x07; out[3] = 0x00;                       /* data size = 7         */
  out[4]  = (unsigned char) ZIP_AES_VENDOR_VERSION;    /* vendor version (LE)   */
  out[5]  = 0x00;
  out[6]  = 'A';  out[7] = 'E';                        /* vendor id "AE"        */
  out[8]  = (unsigned char) strength;                  /* 1/2/3 = 128/192/256   */
  out[9]  = (unsigned char) (real_method & 0xFF);      /* real method (LE)      */
  out[10] = (unsigned char) ((real_method >> 8) & 0xFF);
}

/* Compress (raw deflate, falling back to stored), encrypt and add `plain`
   (`plain_len` bytes) to the open writer `wtr` as a WinZip AES entry under
   `key`. `strength` is 1/2/3 (AES-128/192/256). On a miniz writer failure the
   function sets `*mz_err` to the miniz error string and returns 2; on a crypto
   or allocation failure it returns 1; on success it returns 0. */
static int zip_writer_add_aes(mz_zip_archive *wtr, const char *key,
                              const unsigned char *plain, size_t plain_len,
                              MZ_TIME_T *cmtime, int level,
                              const unsigned char *pw, size_t pwlen,
                              int strength, const char **mz_err) {

  int salt_len = zip_winzip_salt_len(strength);
  int key_len  = zip_winzip_key_len(strength);
  unsigned char salt[16];
  unsigned char enc_key[32], mac_key[32], verifier[2];
  unsigned char mac[20];
  unsigned char extra[ZIP_WINZIP_EXTRA_LEN];
  unsigned char *comp = NULL, *payload = NULL, *ct;
  const unsigned char *data;
  size_t data_len, payload_len;
  int real_method = 0, ret = 1;

  *mz_err = NULL;
  if (salt_len < 0 || key_len < 0) return 1;

  /* 1. Compress with raw deflate. Keep the result only if it actually shrank
     the data; otherwise store it (method 0), mirroring miniz's own writer. */
  if (level > 0 && plain_len > 3) {
    size_t out_len = 0;
    void *p = tdefl_compress_mem_to_heap(
      plain, plain_len, &out_len,
      tdefl_create_comp_flags_from_zip_params(level, -15, MZ_DEFAULT_STRATEGY));
    if (p != NULL && out_len < plain_len) {
      comp = (unsigned char *) p;
      data = comp;
      data_len = out_len;
      real_method = MZ_DEFLATED;
    } else {
      if (p != NULL) free(p);
      data = plain;
      data_len = plain_len;
    }
  } else {
    data = plain;
    data_len = plain_len;
  }

  /* 2. Per-entry random salt, then derive the encryption/authentication keys
     and the 2-byte password verifier. */
  if (zip_rand_bytes(salt, (size_t) salt_len)) goto done;
  if (zip_winzip_aes_keys(pw, pwlen, salt, (size_t) salt_len, strength,
                          enc_key, mac_key, verifier)) goto done;

  /* 3. payload = salt || verifier(2) || ciphertext || authcode(10) */
  payload_len = (size_t) salt_len + 2 + data_len + ZIP_AES_AUTHCODE_LEN;
  payload = malloc(payload_len);
  if (payload == NULL) goto done;
  memcpy(payload, salt, (size_t) salt_len);
  memcpy(payload + salt_len, verifier, 2);
  ct = payload + salt_len + 2;
  if (zip_aes_ctr_crypt(enc_key, key_len * 8, data, ct, data_len)) goto done;

  /* 4. HMAC-SHA1 over the ciphertext, truncated to 10 bytes. */
  if (zip_hmac_sha1(mac_key, (size_t) key_len, ct, data_len, mac)) goto done;
  memcpy(ct + data_len, mac, ZIP_AES_AUTHCODE_LEN);

  /* 5. Write the entry: method 99, encrypted + UTF-8 flags, CRC 0 (AE-2),
     and the 0x9901 extra field in both the local and central headers. */
  zip_winzip_extra_field(extra, strength, real_method);
  if (!mz_zip_writer_add_mem_raw(
        wtr, key, payload, payload_len,
        ZIP_WINZIP_METHOD, /* bit_flags= */ (mz_uint16) (1 | (1 << 11)),
        /* uncomp_crc32= */ 0, (mz_uint64) plain_len, cmtime,
        /* ext_attributes= */ 0,
        (const char *) extra, ZIP_WINZIP_EXTRA_LEN,
        (const char *) extra, ZIP_WINZIP_EXTRA_LEN)) {
    *mz_err = mz_zip_get_error_string(mz_zip_get_last_error(wtr));
    ret = 2;
    goto done;
  }
  ret = 0;

done:
  /* Scrub key material from the stack. */
  memset(enc_key, 0, sizeof(enc_key));
  memset(mac_key, 0, sizeof(mac_key));
  memset(verifier, 0, sizeof(verifier));
  if (comp != NULL) free(comp);
  if (payload != NULL) free(payload);
  return ret;
}

/* Read the whole regular file `fh` (of size `size`) into a freshly malloc'd
   buffer. Returns the buffer (caller frees) or NULL on error. A zero-length
   file yields a 1-byte allocation so the result is never NULL for size 0. */
static unsigned char *zip_read_file_fully(FILE *fh, mz_uint64 size) {
  unsigned char *buf = malloc(size > 0 ? (size_t) size : 1);
  if (buf == NULL) return NULL;
  if (size > 0 && fread(buf, 1, (size_t) size, fh) != (size_t) size) {
    free(buf);
    return NULL;
  }
  return buf;
}

int zip_zip(const char *czipfile, int num_files, const char **ckeys,
	    const char **cfiles, int *cdirs, double *cmtimes,
	    int compression_level, int cappend,
	    const unsigned char *cpassword, size_t cpassword_len,
	    int cencryption,
	    zip_progress_fn progress_fn, void *progress_data) {

  mz_uint ccompression_level = (mz_uint) compression_level;
  int i, n = num_files;
  mz_zip_archive zip_archive;
  memset(&zip_archive, 0, sizeof(zip_archive));
  zip_char_t *filenameu16 = NULL;
  size_t filenameu16_len = 0;
  mz_uint existing_count = 0;
  mz_uint64 bytes_done = 0;

  FILE *zfh = NULL;

  if (cappend) {
    zfh = zip_open_utf8(czipfile, ZIP__APPEND, &filenameu16, &filenameu16_len);
    if (zfh == NULL) {
      if (filenameu16) free(filenameu16);
      ZIP_ERROR(R_ZIP_EOPENAPPEND, czipfile);
    }
    if (!mz_zip_reader_init_cfile(&zip_archive, zfh, 0, 0)) {
      const char *mz_err =
        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
      if (filenameu16) free(filenameu16);
      fclose(zfh);
      ZIP_ERROR_MZ(R_ZIP_EOPENAPPEND, mz_err, czipfile);
    }

    existing_count = mz_zip_reader_get_num_files(&zip_archive);

    /* Determine which existing entries conflict with incoming keys */
    int *skip = NULL;
    int has_replacements = 0;
    if (existing_count > 0 && n > 0) {
      skip = calloc(existing_count, sizeof(int));
      if (!skip) {
        mz_zip_reader_end(&zip_archive);
        fclose(zfh);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
      }
      for (mz_uint j = 0; j < existing_count; j++) {
        mz_zip_archive_file_stat fstat;
        if (!mz_zip_reader_file_stat(&zip_archive, j, &fstat)) continue;
        for (int k = 0; k < n; k++) {
          if (strcmp(fstat.m_filename, ckeys[k]) == 0) {
            skip[j] = 1;
            has_replacements = 1;
            break;
          }
        }
      }
    }

    if (has_replacements) {
      /* Rebuild into a temp file: copy non-replaced entries, then add new ones */
      char *tmp_path = malloc(strlen(czipfile) + 5);
      if (!tmp_path) {
        free(skip);
        mz_zip_reader_end(&zip_archive);
        fclose(zfh);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
      }
      snprintf(tmp_path, strlen(czipfile) + 5, "%s.tmp", czipfile);

      FILE *tmp_fh = zip_open_utf8(tmp_path, ZIP__WRITE, &filenameu16,
                                   &filenameu16_len);
      if (!tmp_fh) {
        free(tmp_path);
        free(skip);
        mz_zip_reader_end(&zip_archive);
        fclose(zfh);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR(R_ZIP_ECREATE, czipfile);
      }

      mz_zip_archive wtr;
      memset(&wtr, 0, sizeof(wtr));
      if (!mz_zip_writer_init_cfile(&wtr, tmp_fh, 0)) {
        const char *mz_err =
          mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
        fclose(tmp_fh);
        zip_remove_file(tmp_path);
        free(tmp_path);
        free(skip);
        mz_zip_reader_end(&zip_archive);
        fclose(zfh);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
      }

      mz_uint num_copied = 0;
      for (mz_uint j = 0; j < existing_count; j++) {
        if (skip[j]) continue;
        if (!mz_zip_writer_add_from_zip_reader(&wtr, &zip_archive, j)) {
          const char *mz_err =
            mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
          mz_zip_writer_end(&wtr);
          fclose(tmp_fh);
          zip_remove_file(tmp_path);
          free(tmp_path);
          free(skip);
          mz_zip_reader_end(&zip_archive);
          fclose(zfh);
          if (filenameu16) free(filenameu16);
          ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
        }
        num_copied++;
      }

      free(skip);
      mz_zip_reader_end(&zip_archive);
      fclose(zfh);
      zfh = NULL;

      for (i = 0; i < n; i++) {
        const char *key = ckeys[i];
        const char *filename = cfiles[i];
        int directory = cdirs[i];
        MZ_TIME_T cmtime = (MZ_TIME_T) cmtimes[i];
        if (directory) {
          if (!mz_zip_writer_add_mem_ex_v2(&wtr, key, 0, 0, 0, 0,
                                           ccompression_level, 0, 0, &cmtime,
                                           0, 0, 0, 0)) {
            const char *mz_err =
              mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
            mz_zip_writer_end(&wtr);
            fclose(tmp_fh);
            zip_remove_file(tmp_path);
            free(tmp_path);
            if (filenameu16) free(filenameu16);
            ZIP_ERROR_MZ(R_ZIP_EADDDIR, mz_err, key, czipfile);
          }
        } else {
          FILE *fh = zip_open_utf8(filename, ZIP__READ, &filenameu16,
                                   &filenameu16_len);
          if (!fh) {
            mz_zip_writer_end(&wtr);
            fclose(tmp_fh);
            zip_remove_file(tmp_path);
            free(tmp_path);
            if (filenameu16) free(filenameu16);
            ZIP_ERROR(R_ZIP_EADDFILE, key, czipfile);
          }
          mz_uint64 uncomp_size = 0;
          if (zip_file_size(fh, &uncomp_size)) {
            fclose(fh);
            mz_zip_writer_end(&wtr);
            fclose(tmp_fh);
            zip_remove_file(tmp_path);
            free(tmp_path);
            if (filenameu16) free(filenameu16);
            ZIP_ERROR(R_ZIP_FILESIZE, filename);
          }
          if (cencryption != ZIP_ENCRYPTION_NONE) {
            unsigned char *plain = zip_read_file_fully(fh, uncomp_size);
            fclose(fh);
            if (!plain) {
              mz_zip_writer_end(&wtr);
              fclose(tmp_fh);
              zip_remove_file(tmp_path);
              free(tmp_path);
              if (filenameu16) free(filenameu16);
              ZIP_ERROR(R_ZIP_EADDFILE, key, czipfile);
            }
            const char *mz_err = NULL;
            int ret = zip_writer_add_aes(&wtr, key, plain, (size_t) uncomp_size,
                                         &cmtime, ccompression_level, cpassword,
                                         cpassword_len, cencryption, &mz_err);
            free(plain);
            if (ret) {
              mz_zip_writer_end(&wtr);
              fclose(tmp_fh);
              zip_remove_file(tmp_path);
              free(tmp_path);
              if (filenameu16) free(filenameu16);
              if (ret == 2) ZIP_ERROR_MZ(R_ZIP_EADDFILE, mz_err, key, czipfile);
              ZIP_ERROR(R_ZIP_EENCRYPT, key, czipfile);
            }
            if (progress_fn) {
              bytes_done += uncomp_size;
              progress_fn(bytes_done, progress_data);
            }
          } else {
            zip_read_ctx_t rctx;
            rctx.fh = fh;
            rctx.bytes_done_ptr = &bytes_done;
            rctx.progress_fn = progress_fn;
            rctx.progress_data = progress_data;
            int ret = mz_zip_writer_add_read_buf_callback(
                &wtr, key, zip_read_with_progress, &rctx, uncomp_size,
                &cmtime, NULL, 0, ccompression_level, NULL, 0, NULL, 0);
            fclose(fh);
            if (!ret) {
              const char *mz_err =
                mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
              mz_zip_writer_end(&wtr);
              fclose(tmp_fh);
              zip_remove_file(tmp_path);
              free(tmp_path);
              if (filenameu16) free(filenameu16);
              ZIP_ERROR_MZ(R_ZIP_EADDFILE, mz_err, key, czipfile);
            }
          }
        }
        if (zip_set_permissions(&wtr, num_copied + i, filename)) {
          mz_zip_writer_end(&wtr);
          fclose(tmp_fh);
          zip_remove_file(tmp_path);
          free(tmp_path);
          if (filenameu16) free(filenameu16);
          ZIP_ERROR(R_ZIP_ESETZIPPERM, key, czipfile);
        }
      }

      if (!mz_zip_writer_finalize_archive(&wtr)) {
        const char *mz_err =
          mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
        mz_zip_writer_end(&wtr);
        fclose(tmp_fh);
        zip_remove_file(tmp_path);
        free(tmp_path);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
      }
      if (!mz_zip_writer_end(&wtr)) {
        const char *mz_err =
          mz_zip_get_error_string(mz_zip_get_last_error(&wtr));
        fclose(tmp_fh);
        zip_remove_file(tmp_path);
        free(tmp_path);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
      }
      fclose(tmp_fh);

      if (zip_rename(tmp_path, czipfile)) {
        zip_remove_file(tmp_path);
        free(tmp_path);
        if (filenameu16) free(filenameu16);
        ZIP_ERROR(R_ZIP_ECREATE, czipfile);
      }
      free(tmp_path);
      if (filenameu16) free(filenameu16);
      return 0;
    }

    /* No replacements: append in-place */
    free(skip);
    if (!mz_zip_writer_init_from_reader(&zip_archive, NULL)) {
      const char *mz_err =
        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
      if (filenameu16) free(filenameu16);
      fclose(zfh);
      ZIP_ERROR_MZ(R_ZIP_EOPENAPPEND, mz_err, czipfile);
    }

  } else {
    zfh = zip_open_utf8(czipfile, ZIP__WRITE, &filenameu16, &filenameu16_len);
    if (zfh == NULL) {
      if (filenameu16) free(filenameu16);
      ZIP_ERROR(R_ZIP_EOPENWRITE, czipfile);
    }
    if (!mz_zip_writer_init_cfile(&zip_archive, zfh, 0)) {
      const char *mz_err =
        mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
      if (filenameu16) free(filenameu16);
      fclose(zfh);
      ZIP_ERROR_MZ(R_ZIP_EOPENWRITE, mz_err, czipfile);
    }
  }

  /* Common path for create and in-place append (no replacements) */
  for (i = 0; i < n; i++) {
    const char *key = ckeys[i];
    const char *filename = cfiles[i];
    int directory = cdirs[i];
    MZ_TIME_T cmtime = (MZ_TIME_T) cmtimes[i];
    if (directory) {
      if (!mz_zip_writer_add_mem_ex_v2(&zip_archive, key, 0, 0, 0, 0,
				       ccompression_level, 0, 0, &cmtime, 0, 0,
				       0, 0)) {
        const char *mz_err =
          mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
        mz_zip_writer_end(&zip_archive);
        if (filenameu16) free(filenameu16);
        fclose(zfh);
        ZIP_ERROR_MZ(R_ZIP_EADDDIR, mz_err, key, czipfile);
      }
    } else {
      FILE *fh = zip_open_utf8(filename, ZIP__READ, &filenameu16,
                               &filenameu16_len);
      if (fh == NULL) {
        mz_zip_writer_end(&zip_archive);
        if (filenameu16) free(filenameu16);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_EADDFILE, key, czipfile);
      }
      mz_uint64 uncomp_size = 0;
      if (zip_file_size(fh, &uncomp_size)) {
        fclose(fh);
        mz_zip_writer_end(&zip_archive);
        if (filenameu16) free(filenameu16);
        fclose(zfh);
        ZIP_ERROR(R_ZIP_FILESIZE, filename);
      }
      if (cencryption != ZIP_ENCRYPTION_NONE) {
        unsigned char *plain = zip_read_file_fully(fh, uncomp_size);
        fclose(fh);
        if (!plain) {
          mz_zip_writer_end(&zip_archive);
          if (filenameu16) free(filenameu16);
          fclose(zfh);
          ZIP_ERROR(R_ZIP_EADDFILE, key, czipfile);
        }
        const char *mz_err = NULL;
        int ret = zip_writer_add_aes(&zip_archive, key, plain,
                                     (size_t) uncomp_size, &cmtime,
                                     ccompression_level, cpassword,
                                     cpassword_len, cencryption, &mz_err);
        free(plain);
        if (ret) {
          mz_zip_writer_end(&zip_archive);
          if (filenameu16) free(filenameu16);
          fclose(zfh);
          if (ret == 2) ZIP_ERROR_MZ(R_ZIP_EADDFILE, mz_err, key, czipfile);
          ZIP_ERROR(R_ZIP_EENCRYPT, key, czipfile);
        }
        if (progress_fn) {
          bytes_done += uncomp_size;
          progress_fn(bytes_done, progress_data);
        }
      } else {
        zip_read_ctx_t rctx;
        rctx.fh = fh;
        rctx.bytes_done_ptr = &bytes_done;
        rctx.progress_fn = progress_fn;
        rctx.progress_data = progress_data;
        int ret = mz_zip_writer_add_read_buf_callback(
            &zip_archive, key, zip_read_with_progress, &rctx,
            /* max_size= */ uncomp_size, /* pFile_time= */ &cmtime,
            /* pComment= */ NULL, /* comment_size= */ 0,
            /* level_and_flags= */ ccompression_level,
            /* user_extra_data_local= */ NULL, /* ...len= */ 0,
            /* user_extra_data_central= */ NULL, /* ...len= */ 0);
        fclose(fh);
        if (!ret) {
          const char *mz_err =
            mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
          mz_zip_writer_end(&zip_archive);
          if (filenameu16) free(filenameu16);
          fclose(zfh);
          ZIP_ERROR_MZ(R_ZIP_EADDFILE, mz_err, key, czipfile);
        }
      }
    }

    if (zip_set_permissions(&zip_archive, existing_count + i, filename)) {
      mz_zip_writer_end(&zip_archive);
      if (filenameu16) free(filenameu16);
      fclose(zfh);
      ZIP_ERROR(R_ZIP_ESETZIPPERM, key, czipfile);
    }
  }

  if (!mz_zip_writer_finalize_archive(&zip_archive)) {
    const char *mz_err =
      mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
    mz_zip_writer_end(&zip_archive);
    if (filenameu16) free(filenameu16);
    fclose(zfh);
    ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
  }

  if (!mz_zip_writer_end(&zip_archive)) {
    const char *mz_err =
      mz_zip_get_error_string(mz_zip_get_last_error(&zip_archive));
    if (filenameu16) free(filenameu16);
    fclose(zfh);
    ZIP_ERROR_MZ(R_ZIP_ECREATE, mz_err, czipfile);
  }

  if (filenameu16) free(filenameu16);
  fclose(zfh);

  return 0;
}
