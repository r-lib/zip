
#include <windows.h>
#include <direct.h>
#include <sys/stat.h>
#include "zip-internals.h"

/* -------------------------------------------------------------- */

int zip__utf8_to_utf16(const char* s, wchar_t** buffer,
                       size_t *buffer_size) {
  int ws_len, r;

  ws_len = MultiByteToWideChar(
    /* CodePage =       */ CP_UTF8,
    /* dwFlags =        */ 0,
    /* lpMultiByteStr = */ s,
    /* cbMultiByte =    */ -1,
    /* lpWideCharStr =  */ NULL,
    /* cchWideChar =    */ 0);

    if (ws_len <= 0) { return GetLastError(); }

    if (*buffer == NULL) {
      /* Let's allocated something bigger, so no need to grow much */
      *buffer_size = ws_len > 255 ? ws_len : 255;
      *buffer = (wchar_t*) calloc(*buffer_size, sizeof(wchar_t));
    } else if (ws_len > *buffer_size) {
      *buffer_size = ws_len;
      *buffer = (wchar_t*) realloc(*buffer, ws_len * sizeof(wchar_t));
    }
    if (*buffer == NULL) { return ERROR_OUTOFMEMORY; }

    r = MultiByteToWideChar(
      /* CodePage =       */ CP_UTF8,
      /* dwFlags =        */ 0,
      /* lpMultiByteStr = */ s,
      /* cbMultiBytes =   */ -1,
      /* lpWideCharStr =  */ *buffer,
      /* cchWideChar =    */ ws_len);

      if (r != ws_len) { return GetLastError(); }

      return 0;
}

int zip_str_file_path(const char *cexdir, const char *key,
                      char **buffer, size_t *buffer_size, int cjunkpaths) {

  size_t len1 = strlen(cexdir);
  size_t need_size, len2;
  char *newbuffer;

  if (cjunkpaths) {
    char *base = strrchr(key, '/');
    if (base) key = base;
  }

  len2 = strlen(key);
  need_size = len1 + len2 + 2;

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

int zip_mkdirp(char *path, int complete)  {
  char *p;
  int status;

  errno = 0;

  /* Iterate the string */
  for (p = path + 1; *p; p++) {
    if (*p == '/') {
      *p = '\0';
      status = _mkdir(path);
      *p = '/';
      if (status && errno != EEXIST) {
        return 1;
      }
    }
  }

  if (complete) {
    status = _mkdir(path);
    if ((status && errno != EEXIST)) return 1;
  }

  return 0;
}

int zip_file_exists(char *filename) {
  struct stat st;
  return ! stat(filename, &st);
}

int zip_set_mtime(const char *filename, time_t mtime) {
  SYSTEMTIME st;
  FILETIME modft;
  struct tm *utctm;
  HANDLE hFile;
  time_t ftimei = (time_t) mtime;

  utctm = gmtime(&ftimei);
  if (!utctm) return 1;

  st.wYear         = (WORD) utctm->tm_year + 1900;
  st.wMonth        = (WORD) utctm->tm_mon + 1;
  st.wDayOfWeek    = (WORD) utctm->tm_wday;
  st.wDay          = (WORD) utctm->tm_mday;
  st.wHour         = (WORD) utctm->tm_hour;
  st.wMinute       = (WORD) utctm->tm_min;
  st.wSecond       = (WORD) utctm->tm_sec;
  st.wMilliseconds = (WORD) 1000*(mtime - ftimei);
  if (!SystemTimeToFileTime(&st, &modft)) return 1;

  hFile = CreateFile(filename, GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
                     FILE_FLAG_BACKUP_SEMANTICS, NULL);
  if (hFile == INVALID_HANDLE_VALUE) return 1;
  int res  = SetFileTime(hFile, NULL, NULL, &modft);
  CloseHandle(hFile);
  return res == 0; /* success is non-zero */
}
