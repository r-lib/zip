
#include <stdlib.h>
#include <time.h>

#include <Rinternals.h>

#include "zip.h"

SEXP R_zip_zip(SEXP zipfile, SEXP keys, SEXP files, SEXP dirs, SEXP mtime,
	       SEXP compression_level, SEXP append) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  int ccompression_level = INTEGER(compression_level)[0];
  int cappend = LOGICAL(append)[0];
  int i, n = LENGTH(files);

  struct zip_t *zip = zip_open(czipfile, ccompression_level,
			       cappend ? 'a' : 'w');
  if (!zip) error("Can't open zip file");

  for (i = 0; i < n; i++) {
    const char *key = CHAR(STRING_ELT(keys, i));
    const char *filename = CHAR(STRING_ELT(files, i));
    int directory = LOGICAL(dirs)[i];
    time_t cmtime = REAL(mtime)[i];
    if (zip_entry_open(zip, key)) error("Can't create zip file entry");
    if (zip_entry_fwrite(zip, filename, directory)) error("Can't write zip file entry");
    if (zip_entry_close(zip, cmtime)) error("Can't close zip file entry");
  }

  zip_close(zip);

  return R_NilValue;
}

SEXP R_zip_list(SEXP zipfile) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  char **files;
  size_t *compressed_size;
  size_t *uncompressed_size;
  time_t *timestamps;
  size_t i, num_files;
  SEXP result = R_NilValue;

  int status = zip_list(czipfile, &num_files, &files, &compressed_size,
			&uncompressed_size, &timestamps);

  if (status) error("Cannot list zip file contents");

  result = PROTECT(allocVector(VECSXP, 4));
  SET_VECTOR_ELT(result, 0, allocVector(STRSXP, num_files));
  SET_VECTOR_ELT(result, 1, allocVector(REALSXP, num_files));
  SET_VECTOR_ELT(result, 2, allocVector(REALSXP, num_files));
  SET_VECTOR_ELT(result, 3, allocVector(INTSXP, num_files));

  for (i = 0; i < num_files; ++i) {
    SET_STRING_ELT(VECTOR_ELT(result, 0), i, mkChar(files[i]));
    REAL(VECTOR_ELT(result, 1))[i] = compressed_size[i];
    REAL(VECTOR_ELT(result, 2))[i] = uncompressed_size[i];
    INTEGER(VECTOR_ELT(result, 3))[i] = timestamps[i];
    free(files[i]);
  }
  free(files);
  free(compressed_size);
  free(uncompressed_size);
  free(timestamps);

  UNPROTECT(1);
  return result;
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
  fstore_t store = { F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, sz };
  // Try to get a continous chunk of disk space
  int ret = fcntl(fd, F_PREALLOCATE, &store);
  if (-1 == ret) {
    // OK, perhaps we are too fragmented, allocate non-continuous
    store.fst_flags = F_ALLOCATEALL;
    ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) error("Cannot create big file");
  }

  if (ftruncate(fd, sz)) {
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
