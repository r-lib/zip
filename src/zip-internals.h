
#ifndef R_ZIP_INTERNALS_H
#define R_ZIP_INTERNALS_H

#include <time.h>

#ifdef _WIN32

#include <windows.h>

#define zip_char_t wchar_t

int zip__utf8_to_utf16(const char* s, wchar_t** buffer,
                       size_t *buffer_size);

#else

#define zip_char_t char

#endif

int zip_str_file_path(const char *cexdir, const char *key,
                      zip_char_t **buffer, size_t *buffer_size,
                      int cjunkpaths);
int zip_mkdirp(zip_char_t *path, int complete);
int zip_set_mtime(const zip_char_t *filename, time_t mtime);
int zip_file_exists(zip_char_t *filename);
int zip_set_mtime(const zip_char_t *filename, time_t mtime);

#endif
