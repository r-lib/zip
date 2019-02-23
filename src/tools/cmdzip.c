
#include <fcntl.h>
#include <unistd.h>

#include "../zip.h"

#define ERROR(x) while (1) { retval = (x); goto cleanup; }

void cmd_zip_error_handler(const char *reason, const char *file,
			   int line, int zip_errno, int eno) {
  fprintf(stderr, "zip error: `%s` in file `%s:%i`", reason, file, line);
}

int main(int argc, char* argv[]) {
  int i, num_files = 0;
  int ckeysbytes, cfilesbytes;
  char *keysbuffer = 0, *filesbuffer = 0;
  const char **ckeys = 0, **cfiles = 0;
  int *cdirs = 0;
  double *ctimes = 0;
  int fd = -1;
  int retval = 0;
  char *ptr;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s zip-file input-file\n", argv[0]);
    return 1;
  }

  if ((fd = open(argv[2], O_RDONLY)) == -1) ERROR(1);

  /* Number of keys */
  if (read(fd, &num_files, sizeof(num_files)) != sizeof(num_files)) {
    ERROR(2);
  }

  ckeys  = calloc(num_files, sizeof(const char*));
  cfiles = calloc(num_files, sizeof(const char*));
  cdirs  = calloc(num_files, sizeof(int));
  ctimes = calloc(num_files, sizeof(double));

  if (!ckeys || !cfiles || !cdirs || !ctimes) ERROR(3);

  /* keys first the total size of the buffer in bytes */
  if (read(fd, &ckeysbytes, sizeof(ckeysbytes)) != sizeof(ckeysbytes)) {
    ERROR(4);
  }
  keysbuffer = malloc(ckeysbytes);
  if (!keysbuffer) ERROR(5);
  if (read(fd, keysbuffer, ckeysbytes) != ckeysbytes) ERROR(6);
  for (i = 0, ptr = keysbuffer; i < num_files; ptr++, i++) {
    ckeys[i] = ptr;
    while (*ptr != '\0') ++ptr;
  }

  /* file names next */
  if (read(fd, &cfilesbytes, sizeof(cfilesbytes)) != sizeof(cfilesbytes)) {
    ERROR(4);
  }
  filesbuffer = malloc(cfilesbytes);
  if (!filesbuffer) ERROR(7);
  if (read(fd, filesbuffer, cfilesbytes) != cfilesbytes) ERROR(8);
  for (i = 0, ptr = filesbuffer; i < num_files; ptr++, i++) {
    cfiles[i] = ptr;
    while (*ptr != '\0') ++ptr;
  }

  /* dirs */
  if (read(fd, cdirs, num_files * sizeof(int)) != num_files * sizeof(int)) {
    ERROR(9);
  }

  /* mtimes */
  if (read(fd, ctimes, num_files * sizeof(double)) !=
      num_files * sizeof(double)) {
    ERROR(10);
  }

  zip_set_error_handler(cmd_zip_error_handler);

  if (zip_zip(argv[1], num_files, ckeys, cfiles, cdirs, ctimes,
	      /* compression_level= */ 9, /* cappend= */ 0)) {
    ERROR(11);
  }

 cleanup:
  if (ckeys)       free(ckeys);
  if (cfiles)      free(cfiles);
  if (cdirs)       free(cdirs);
  if (ctimes)      free(ctimes);
  if (keysbuffer)  free(keysbuffer);
  if (filesbuffer) free(filesbuffer);

  if (retval != 0) {
    fprintf(stderr, "Failed to create zip archive %s", argv[1]);
  }

  return retval;
}
