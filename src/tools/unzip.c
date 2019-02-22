
#include <stdio.h>

#include "../zip.h"

int main(int argc, char* argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s zip-file target-dir\n", argv[0]);
    return 1;
  }

  zip_unzip(argv[1], /* cfiles= */ 0, /* num_files= */ 0,
	    /* coverwrite= */ 1, /* cjunkpaths= */ 0, /* exdir= */ argv[2]);

  return 0;
}
