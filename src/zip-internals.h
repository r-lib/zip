
#ifndef R_ZIP_INTERNALS_H
#define R_ZIP_INTERNALS_H

#include <time.h>

#ifdef _WIN32

#include <windows.h>

int zip__utf8_to_utf16(const char* s, wchar_t** buffer,
                       size_t *buffer_size);
int zip_str_file_path(const char *cexdir, const char *key,
                      char **buffer, size_t *buffer_size,
                      int cjunkpaths);
int zip_mkdirp(char *path, int complete);
int zip_set_mtime(const char *filename, time_t mtime);
int zip_file_exists(char *filename);
int zip_set_mtime(const char *filename, time_t mtime);

#else

int zip_str_file_path(const char *cexdir, const char *key,
                      char **buffer, size_t *buffer_size,
                      int cjunkpaths);
int zip_mkdirp(char *path, int complete);
int zip_file_exists(char *filename);
int zip_set_mtime(const char *filename, time_t mtime);

#endif

#endif
