
#include <stdio.h>

#include "../zip.h"

static void cmd_zip_error_handler(const char *reason, const char *file,
                                  int line, int zip_errno, int eno) {
  fprintf(stderr, "zip error: `%s` in file `%s:%i`\n", reason, file, line);
  if (eno < 0) {
    eno = - eno;
  } else if (eno == 0) {
    eno = 1;
  }
  exit(eno);
}

int main(int argc, char* argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s zip-file target-dir\n", argv[0]);
    return 1;
  }

  zip_set_error_handler(cmd_zip_error_handler);

  zip_unzip(argv[1], /* cfiles= */ 0, /* num_files= */ 0,
	    /* coverwrite= */ 1, /* cjunkpaths= */ 0, /* exdir= */ argv[2]);

  return 0;
}
