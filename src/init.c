
#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* .Call calls */
extern SEXP R_zip_list(SEXP);

static const R_CallMethodDef CallEntries[] = {
  { "R_zip_list",      (DL_FUNC) &R_zip_list,      1 },
  { NULL, NULL, 0 }
};

void R_init_ziplist64(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}
