
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>

#include <Rinternals.h>

#include "miniz.h"

SEXP R_zip_zip(SEXP zipfile, SEXP keys, SEXP files, SEXP dirs, SEXP mtime,
	       SEXP compression_level, SEXP append) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  mz_uint ccompression_level =(mz_uint) INTEGER(compression_level)[0];
  int cappend = LOGICAL(append)[0];
  int i, n = LENGTH(files);
  mz_zip_archive zip_archive;

  memset(&zip_archive, 0, sizeof(zip_archive));

  if (cappend) {
    if (!mz_zip_reader_init_file(&zip_archive, czipfile, 0) ||
	!mz_zip_writer_init_from_reader(&zip_archive, czipfile)) {
      error("Cannot open zip file `%s` for appending", czipfile);
    }
  } else {
    if (!mz_zip_writer_init_file(&zip_archive, czipfile, 0)) {
      error("Cannot open zip file `%s` for writing", czipfile);
    }
  }

  for (i = 0; i < n; i++) {
   const char *key = CHAR(STRING_ELT(keys, i));
   const char *filename = CHAR(STRING_ELT(files, i));
   int directory = LOGICAL(dirs)[i];
   if (directory) {
     MZ_TIME_T cmtime = (MZ_TIME_T) REAL(mtime)[i];
     if (!mz_zip_writer_add_mem_ex_v2(&zip_archive, key, 0, 0, 0, 0,
				      ccompression_level, 0, 0, &cmtime, 0, 0,
				      0, 0)) {
       goto cleanup;
     }

   } else {
     if (!mz_zip_writer_add_file(&zip_archive, key, filename, 0, 0,
				 ccompression_level)) {
       goto cleanup;
     }
   }
  }

  if (!mz_zip_writer_finalize_archive(&zip_archive)) goto cleanup;
  if (!mz_zip_writer_end(&zip_archive)) goto cleanup;

  /* TODO: return info */
  return R_NilValue;

 cleanup:
  mz_zip_writer_end(&zip_archive);
  error("Cannot create zip file `%s`, file might be corrupt", czipfile);
  return R_NilValue;
}

SEXP R_zip_list(SEXP zipfile) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  size_t num_files;
  unsigned int i;
  SEXP result = R_NilValue;
  mz_bool status;
  mz_zip_archive zip_archive;

  memset(&zip_archive, 0, sizeof(zip_archive));
  status = mz_zip_reader_init_file(&zip_archive, czipfile, 0);
  if (!status) error("Cannot open zip file `%s`", czipfile);

  num_files = mz_zip_reader_get_num_files(&zip_archive);
  result = PROTECT(allocVector(VECSXP, 4));
  SET_VECTOR_ELT(result, 0, allocVector(STRSXP, num_files));
  SET_VECTOR_ELT(result, 1, allocVector(REALSXP, num_files));
  SET_VECTOR_ELT(result, 2, allocVector(REALSXP, num_files));
  SET_VECTOR_ELT(result, 3, allocVector(INTSXP, num_files));

  for (i = 0; i < num_files; i++) {
    mz_zip_archive_file_stat file_stat;
    status = mz_zip_reader_file_stat (&zip_archive, i, &file_stat);
    if (!status) goto cleanup;

    SET_STRING_ELT(VECTOR_ELT(result, 0), i, mkChar(file_stat.m_filename));
    REAL(VECTOR_ELT(result, 1))[i] = file_stat.m_comp_size;
    REAL(VECTOR_ELT(result, 2))[i] = file_stat.m_uncomp_size;
    INTEGER(VECTOR_ELT(result, 3))[i] = (int) file_stat.m_time;
  }

  mz_zip_reader_end(&zip_archive);
  UNPROTECT(1);
  return result;

 cleanup:
  mz_zip_reader_end(&zip_archive);
  error("Cannot list zip entries, corrupt zip file?");
  return result;
}

int zip_str_file_path(const char *cexdir, const char *key,
		      char **buffer, size_t *buffer_size) {
  size_t len1 = strlen(cexdir);
  size_t len2 = strlen(key);
  size_t need_size = len1 + len2 + 2;
  char *newbuffer;

  if (*buffer_size < need_size) {
    newbuffer = realloc((void*) *buffer, need_size);
    if (!newbuffer) return 1;

    *buffer = newbuffer;
    *buffer_size = need_size;
  }

  strcpy(*buffer, cexdir);
  (*buffer)[len1] = '/';
  strcpy(*buffer + len1 + 1, key);

  return 0;
}

int zip_mkdirp(char *path)  {
  char *p;
  int status;

  errno = 0;

  /* Iterate the string */
  for (p = path + 1; *p; p++) {
    if (*p == '/') {
      *p = '\0';
#ifdef _WIN32
      status = _mkdir(path);
#else
      status = mkdir(path, S_IRWXU);
#endif
      *p = '/';
      if (status && errno != EEXIST) return 1;
    }
  }

#ifdef _WIN32
  status = _mkdir(path);
#else
  status = mkdir(path, S_IRWXU);
#endif
  if (status &&  errno != EEXIST) return 1;

  return 0;
}

SEXP R_zip_unzip(SEXP zipfile, SEXP files, SEXP overwrite, SEXP junkpaths,
		 SEXP exdir) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  int coverwrite = LOGICAL(overwrite)[0];
  int cjunkpaths = LOGICAL(junkpaths)[0];
  const char *cexdir = CHAR(STRING_ELT(exdir, 0));
  int allfiles = isNull(files);
  int i, n;
  mz_zip_archive zip_archive;
  char *buffer = 0;
  size_t buffer_size = 0;

  memset(&zip_archive, 0, sizeof(zip_archive));

  if (!mz_zip_reader_init_file(&zip_archive, czipfile, 0)) {
    error("Cannot open zip file `%s` for reading", czipfile);
  }

  /* We allocate a fairly large buffer for the destination file names here,
     so that we don't need to reallocated it all the time */
  buffer_size = 10;
  buffer = malloc(buffer_size);
  if (!buffer) {
    mz_zip_reader_end(&zip_archive);
    error("Cannot extract zip archive `%s`, out of memory", czipfile);
  }

  n = allfiles ? mz_zip_reader_get_num_files(&zip_archive) : LENGTH(files);

  for (i = 0; i < n; i++) {
    mz_uint32 idx = -1;
    const char *key = 0;
    mz_zip_archive_file_stat file_stat;

    if (allfiles) {
      idx = (mz_uint32) i;
    } else {
      key = CHAR(STRING_ELT(files, i));
      if (mz_zip_reader_locate_file_v2(&zip_archive, key, /* pComment= */ 0,
				       /* flags= */ 0, &idx)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	error("Cannot extract file `%s` from archive `%s`", key, czipfile);
      }
    }

    if (! mz_zip_reader_file_stat (&zip_archive, idx, &file_stat)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      error("Cannot extract zip archive `%s`", czipfile);
    }
    key = file_stat.m_filename;

    if (zip_str_file_path(cexdir, key, &buffer, &buffer_size)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      error("Cannot extract zip archive `%s`, out of memory", czipfile);
    }

    if (file_stat.m_is_directory) {
      zip_mkdirp(buffer);
      /* TODO: set modification time */

    } else {
      if (!mz_zip_reader_extract_to_file(&zip_archive, idx, buffer, 0)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	error("Cannot extract file `%s` from archive `%s`", key, czipfile);
      }
    }
  }

  mz_zip_reader_end(&zip_archive);

  /* TODO: return info */
  return R_NilValue;
}

#ifdef _WIN32
#include <windows.h>

int zip__utf8_to_utf16_alloc(const char* s, WCHAR** ws_ptr) {
  int ws_len, r;
  WCHAR* ws;

  ws_len = MultiByteToWideChar(
    /* CodePage =       */ CP_UTF8,
    /* dwFlags =        */ 0,
    /* lpMultiByteStr = */ s,
    /* cbMultiByte =    */ -1,
    /* lpWideCharStr =  */ NULL,
    /* cchWideChar =    */ 0);

  if (ws_len <= 0) { return GetLastError(); }

  ws = (WCHAR*) R_alloc(ws_len,  sizeof(WCHAR));
  if (ws == NULL) { return ERROR_OUTOFMEMORY; }

  r = MultiByteToWideChar(
    /* CodePage =       */ CP_UTF8,
    /* dwFlags =        */ 0,
    /* lpMultiByteStr = */ s,
    /* cbMultiBytes =   */ -1,
    /* lpWideCharStr =  */ ws,
    /* cchWideChar =    */ ws_len);

  if (r != ws_len) {
    error("processx error interpreting UTF8 command or arguments");
  }

  *ws_ptr = ws;
  return 0;
}

#endif

#ifdef __APPLE__
#include <fcntl.h>
#include <unistd.h>
#endif

SEXP R_make_big_file(SEXP filename, SEXP mb) {

#ifdef _WIN32

  const char *cfilename = CHAR(STRING_ELT(filename, 0));
  WCHAR *wfilename = NULL;
  LARGE_INTEGER li;

  if (zip__utf8_to_utf16_alloc(cfilename, &wfilename)) {
    error("utf8 -> utf16 conversion");
  }

  HANDLE h = CreateFileW(
    wfilename,
    GENERIC_WRITE,
    FILE_SHARE_DELETE,
    NULL,
    CREATE_NEW,
    FILE_ATTRIBUTE_NORMAL,
    NULL);
  if (h == INVALID_HANDLE_VALUE) error("Cannot create big file");

  li.QuadPart = INTEGER(mb)[0] * 1024.0 * 1024.0;
  li.LowPart = SetFilePointer(h, li.LowPart, &li.HighPart, FILE_BEGIN);

  if (0xffffffff == li.LowPart && GetLastError() != NO_ERROR) {
    CloseHandle(h);
    error("Cannot create big file");
  }

  if (!SetEndOfFile(h)) {
    CloseHandle(h);
    error("Cannot create big file");
  }

  CloseHandle(h);

#endif

#ifdef __APPLE__

  const char *cfilename = CHAR(STRING_ELT(filename, 0));
  int fd = open(cfilename, O_WRONLY | O_CREAT);
  double sz = INTEGER(mb)[0] * 1024.0 * 1024.0;
  fstore_t store = { F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, (off_t) sz };
  // Try to get a continous chunk of disk space
  int ret = fcntl(fd, F_PREALLOCATE, &store);
  if (-1 == ret) {
    // OK, perhaps we are too fragmented, allocate non-continuous
    store.fst_flags = F_ALLOCATEALL;
    ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) error("Cannot create big file");
  }

  if (ftruncate(fd, (off_t) sz)) {
    close(fd);
    error("Cannot create big file");
  }

  close(fd);

#endif

#ifndef _WIN32
#ifndef __APPLE__
  error("cannot create big file (only implemented for windows and macos");
#endif
#endif

  return R_NilValue;
}
