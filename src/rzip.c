
#include <stdlib.h>

#include <Rinternals.h>

#include "zip.h"

SEXP R_zip_zip(SEXP zipfile, SEXP files, SEXP compression_level,
	       SEXP append) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  int ccompression_level = INTEGER(compression_level)[0];
  int cappend = LOGICAL(append)[0];
  int i, n = LENGTH(files);

  struct zip_t *zip = zip_open(czipfile, ccompression_level,
			       cappend ? 'a' : 'w');
  if (!zip) error("Can't open zip file");

  for (i = 0; i < n; i++) {
    const char *entry = CHAR(STRING_ELT(files, i));
    if (zip_entry_open(zip, entry)) error("Can't create zip file entry");
    if (zip_entry_fwrite(zip, entry)) error("Can't write zip file entry");
    if (zip_entry_close(zip)) error("Can't close zip file entry");
  }

  zip_close(zip);

  return R_NilValue;
}

SEXP R_zip_list(SEXP zipfile) {
  const char *czipfile = CHAR(STRING_ELT(zipfile, 0));
  char **files;
  size_t *compressed_size;
  size_t *uncompressed_size;
  size_t i, num_files;
  SEXP result = R_NilValue;

  int status = zip_list(czipfile, &num_files, &files, &compressed_size,
			&uncompressed_size);

  if (status) error("Cannot list zip file contents");

  result = PROTECT(allocVector(VECSXP, 3));
  SET_VECTOR_ELT(result, 0, allocVector(STRSXP, num_files));
  SET_VECTOR_ELT(result, 1, allocVector(INTSXP, num_files));
  SET_VECTOR_ELT(result, 2, allocVector(INTSXP, num_files));

  for (i = 0; i < num_files; ++i) {
    SET_STRING_ELT(VECTOR_ELT(result, 0), i, mkChar(files[i]));
    INTEGER(VECTOR_ELT(result, 1))[i] = compressed_size[i];
    INTEGER(VECTOR_ELT(result, 2))[i] = uncompressed_size[i];
    free(files[i]);
  }
  free(files);
  free(compressed_size);
  free(uncompressed_size);

  UNPROTECT(1);
  return result;
}
