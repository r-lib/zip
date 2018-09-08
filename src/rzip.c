
#include <stdlib.h>
#include <time.h>

#include <Rinternals.h>

#include "zip.h"

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

