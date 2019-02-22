
#ifndef R_ZIP_H
#define R_ZIP_H

#include "miniz.h"

typedef enum zip_error_codes {
  R_ZIP_ESUCCESS     = 0,
  R_ZIP_EOPEN        = 1,
  R_ZIP_ENOMEM       = 2,
  R_ZIP_ENOENTRY     = 3,
  R_ZIP_EBROKEN      = 4,
  R_ZIP_EBROKENENTRY = 5,
  R_ZIP_EOVERWRITE   = 6,
  R_ZIP_ECREATEDIR   = 7,
  R_ZIP_ESETPERM     = 8,
  R_ZIP_ESETMTIME    = 9
} zip_error_codes_t;

typedef void zip_error_handler_t(const char *reason, const char *file,
				 int line, int zip_errno, int eno);

void zip_set_error_handler(zip_error_handler_t *handler);

int zip_get_permissions(mz_zip_archive_file_stat *stat, mode_t *mode);

int zip_set_permissions(mz_zip_archive *zip_archive, mz_uint file_index,
			const char *filename);

int zip_unzip(const char *czipfile, const char **cfiles, int num_files,
	      int coverwrite, int cjunkpaths, const char *exdir);

#endif
