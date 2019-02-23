
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <stdarg.h>

#ifdef _WIN32
#include <direct.h>		/* _mkdir */
#include <windows.h>
#endif

#include "miniz.h"
#include "zip.h"

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
  /*15 R_ZIP_ECREATE      */ "Could not create zip archive `%s`"
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
  external_attr |= st.st_mode << 16;

  if (! mz_zip_set_version_made_by(zip_archive, file_index, version_by) ||
      ! mz_zip_set_external_attr(zip_archive, file_index, external_attr)) {
    return 1;
  }

  return 0;
#endif
}

#ifdef _WIN32
int zip_get_permissions(mz_zip_archive_file_stat *stat, mode_t *mode) {
  *mode = stat->m_is_directory ? 0700 : 0600;
  return 0;
}
#else
int zip_get_permissions(mz_zip_archive_file_stat *stat, mode_t *mode) {
  mz_uint16 version_by = (stat->m_version_made_by >> 8) & 0xFF;
  mz_uint32 external_attr = (stat->m_external_attr >> 16) & 0xFFFF;

  /* If it is not made by Unix, or the permission field is zero,
     we ignore them. */
  if (version_by != 3 || external_attr == 0) {
    *mode = stat->m_is_directory ? 0700 : 0600;
  } else {
    *mode = (mode_t) external_attr & 0777;
  }

  return 0;
}
#endif

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
#ifdef _WIN32
      status = _mkdir(path);
#else
      status = mkdir(path, S_IRWXU);
#endif
      *p = '/';
      if (status && errno != EEXIST) {
	  return 1;
      }
    }
  }

  if (complete) {
#ifdef _WIN32
    status = _mkdir(path);
#else
    status = mkdir(path, S_IRWXU);
#endif
    if ((status && errno != EEXIST)) return 1;
  }

  return 0;
}

int zip_file_exists(char *filename) {
  struct stat st;
  return ! stat(filename, &st);
}

int zip_set_mtime(const char *filename, time_t mtime) {
#ifdef _WIN32
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

#else
  struct timeval times[2];
  times[0].tv_sec  = times[1].tv_sec = mtime;
  times[0].tv_usec = times[1].tv_usec = 0;
  return utimes(filename, times);
#endif
}

int zip_unzip(const char *czipfile, const char **cfiles, int num_files,
	      int coverwrite, int cjunkpaths, const char *cexdir) {

  int allfiles = cfiles == NULL;
  int i, n;
  mz_zip_archive zip_archive;
  char *buffer = 0;
  size_t buffer_size = 0;

  memset(&zip_archive, 0, sizeof(zip_archive));

  if (!mz_zip_reader_init_file(&zip_archive, czipfile, 0)) {
    ZIP_ERROR(R_ZIP_EOPEN, czipfile);
  }

  /* We allocate a fairly large buffer for the destination file names here,
     so that we don't need to reallocated it all the time */
  buffer_size = 1000;
  buffer = malloc(buffer_size);
  if (!buffer) {
    mz_zip_reader_end(&zip_archive);
    ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
  }

  n = allfiles ? mz_zip_reader_get_num_files(&zip_archive) : num_files;

  for (i = 0; i < n; i++) {
    mz_uint32 idx = -1;
    const char *key = 0;
    mz_zip_archive_file_stat file_stat;

    if (allfiles) {
      idx = (mz_uint32) i;
    } else {
      key = cfiles[i];
      if (!mz_zip_reader_locate_file_v2(&zip_archive, key, /* pComment= */ 0,
				       /* flags= */ 0, &idx)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	ZIP_ERROR(R_ZIP_ENOENTRY, key, czipfile);
      }
    }

    if (! mz_zip_reader_file_stat(&zip_archive, idx, &file_stat)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      ZIP_ERROR(R_ZIP_EBROKEN, czipfile);
    }
    key = file_stat.m_filename;

    if (zip_str_file_path(cexdir, key, &buffer, &buffer_size, cjunkpaths)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      ZIP_ERROR(R_ZIP_ENOMEM, czipfile);
    }

    if (file_stat.m_is_directory) {
      if (! cjunkpaths && zip_mkdirp(buffer, 1)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	ZIP_ERROR(R_ZIP_EBROKENENTRY, key, czipfile);
      }

    } else {
      if (!coverwrite && zip_file_exists(buffer)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	ZIP_ERROR(R_ZIP_EOVERWRITE, key, czipfile);
      }

      if (! cjunkpaths && zip_mkdirp(buffer, 0)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	ZIP_ERROR(R_ZIP_ECREATEDIR, key, czipfile);
      }

      if (!mz_zip_reader_extract_to_file(&zip_archive, idx, buffer, 0)) {
	mz_zip_reader_end(&zip_archive);
	if (buffer) free(buffer);
	ZIP_ERROR(R_ZIP_EBROKENENTRY, key, czipfile);
      }
    }
#ifndef _WIN32
    mode_t mode;
    zip_get_permissions(&file_stat, &mode);
    if (chmod(buffer, mode)) {
      mz_zip_reader_end(&zip_archive);
      if (buffer) free(buffer);
      ZIP_ERROR(R_ZIP_ESETPERM, key, czipfile);
    }
#endif
  }

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

    if (file_stat.m_is_directory) {
      zip_str_file_path(cexdir, key, &buffer, &buffer_size, cjunkpaths);
      if (zip_set_mtime(buffer, file_stat.m_time)) {
	if (buffer) free(buffer);
	mz_zip_reader_end(&zip_archive);
	ZIP_ERROR(R_ZIP_ESETMTIME, key, czipfile);
      }
    }
  }

  if (buffer) free(buffer);
  mz_zip_reader_end(&zip_archive);

  /* TODO: return info */
  return 0;
}

int zip_zip(const char *czipfile, int num_files, const char **ckeys,
	    const char **cfiles, int *cdirs, double *cmtimes,
	    int compression_level, int cappend) {

  mz_uint ccompression_level = (mz_uint) compression_level;
  int i, n = num_files;
  mz_zip_archive zip_archive;

  memset(&zip_archive, 0, sizeof(zip_archive));

  if (cappend) {
    if (!mz_zip_reader_init_file(&zip_archive, czipfile, 0) ||
	!mz_zip_writer_init_from_reader(&zip_archive, czipfile)) {
      ZIP_ERROR(R_ZIP_EOPENAPPEND, czipfile);
    }
  } else {
    if (!mz_zip_writer_init_file(&zip_archive, czipfile, 0)) {
      ZIP_ERROR(R_ZIP_EOPENWRITE, czipfile);
    }
  }

  for (i = 0; i < n; i++) {
    const char *key = ckeys[i];
    const char *filename = cfiles[i];
    int directory = cdirs[i];
    if (directory) {
      MZ_TIME_T cmtime = (MZ_TIME_T) cmtimes[i];
      if (!mz_zip_writer_add_mem_ex_v2(&zip_archive, key, 0, 0, 0, 0,
				       ccompression_level, 0, 0, &cmtime, 0, 0,
				       0, 0)) {
	mz_zip_writer_end(&zip_archive);
	ZIP_ERROR(R_ZIP_EADDDIR, key, czipfile);
      }

    } else {
      if (!mz_zip_writer_add_file(&zip_archive, key, filename, 0, 0,
				  ccompression_level)) {
	mz_zip_writer_end(&zip_archive);
	ZIP_ERROR(R_ZIP_EADDFILE, key, czipfile);
      }
    }

    if (zip_set_permissions(&zip_archive, i, filename)) {
      mz_zip_writer_end(&zip_archive);
      ZIP_ERROR(R_ZIP_ESETZIPPERM, key, czipfile);
    }
  }

  if (!mz_zip_writer_finalize_archive(&zip_archive)) {
    mz_zip_writer_end(&zip_archive);
    ZIP_ERROR(R_ZIP_ECREATE, czipfile);
  }

  if (!mz_zip_writer_end(&zip_archive)) {
    ZIP_ERROR(R_ZIP_ECREATE, czipfile);
  }

  /* TODO: return info */
  return 0;
}
