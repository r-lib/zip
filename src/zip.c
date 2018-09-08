/*
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#include "zip.h"
#include "miniz.h"

#include <errno.h>
#include <sys/stat.h>
#include <time.h>

#if defined _WIN32 || defined __WIN32__
/* Win32, DOS */
#include <direct.h>

#define MKDIR(DIRNAME) _mkdir(DIRNAME)
#define STRCLONE(STR) ((STR) ? _strdup(STR) : NULL)
#define HAS_DEVICE(P)                                                          \
    ((((P)[0] >= 'A' && (P)[0] <= 'Z') || ((P)[0] >= 'a' && (P)[0] <= 'z')) && \
     (P)[1] == ':')
#define FILESYSTEM_PREFIX_LEN(P) (HAS_DEVICE(P) ? 2 : 0)
#define ISSLASH(C) ((C) == '/' || (C) == '\\')

#else
#define MKDIR(DIRNAME) mkdir(DIRNAME, 0755)
#define STRCLONE(STR) ((STR) ? strdup(STR) : NULL)
#endif

#ifndef FILESYSTEM_PREFIX_LEN
#define FILESYSTEM_PREFIX_LEN(P) 0
#endif

#ifndef ISSLASH
#define ISSLASH(C) ((C) == '/')
#endif

#define CLEANUP(ptr)           \
    do {                       \
        if (ptr) {             \
            free((void *)ptr); \
            ptr = NULL;        \
        }                      \
    } while (0)

static char *basename(const char *name) {
    char const *p;
    char const *base = name += FILESYSTEM_PREFIX_LEN(name);
    int all_slashes = 1;

    for (p = name; *p; p++) {
        if (ISSLASH(*p))
            base = p + 1;
        else
            all_slashes = 0;
    }

    /* If NAME is all slashes, arrange to return `/'. */
    if (*base == '\0' && ISSLASH(*name) && all_slashes) --base;

    return (char *)base;
}

static int mkpath(const char *path) {
    char const *p;
    char npath[MAX_PATH + 1] = {0};
    int len = 0;

    for (p = path; *p && len < MAX_PATH; p++) {
        if (ISSLASH(*p) && len > 0) {
            if (MKDIR(npath) == -1)
                if (errno != EEXIST) return -1;
        }
        npath[len++] = *p;
    }

    return 0;
}

static char *strrpl(const char *str, char oldchar, char newchar) {
    char *rpl = (char *)malloc(sizeof(char) * (1 + strlen(str)));
    char *begin = rpl;
    char c;
    while((c = *str++)) {
        if (c == oldchar) {
            c = newchar;
        }
        *rpl++ = c;
    }
    *rpl = '\0';

    return begin;
}

struct zip_entry_t {
    int index;
    const char *name;
    mz_uint64 uncomp_size;
    mz_uint64 comp_size;
    mz_uint32 uncomp_crc32;
    mz_uint64 offset;
    mz_uint8 header[MZ_ZIP_LOCAL_DIR_HEADER_SIZE];
    mz_uint64 header_offset;
    mz_uint16 method;
    mz_zip_writer_add_state state;
    tdefl_compressor comp;
};

struct zip_t {
    mz_zip_archive archive;
    mz_uint level;
    struct zip_entry_t entry;
    char mode;
};

int zip_list(const char *zipname, size_t *num, char ***files,
	     size_t **compressed_size, size_t **uncompressed_size,
	     time_t **timestamps) {

    mz_uint i, n = 0;
    mz_zip_archive zip_archive;
    mz_zip_archive_file_stat info;
    int status = 0;

    if (!memset(&(zip_archive), 0, sizeof(zip_archive))) {
        // Cannot memset zip archive
        return -1;
    }

    if (!zipname) {
        // Cannot parse zip archive name
        return -1;
    }

    if (!mz_zip_reader_init_file(&zip_archive, zipname, 0)) {
        // Cannot initialize zip_archive reader
        return -1;
    }

    *num = n = mz_zip_reader_get_num_files(&zip_archive);
    *files = 0;
    *compressed_size = 0;
    *uncompressed_size = 0;
    *timestamps = 0;
    *files = calloc(n, sizeof(char *));
    *compressed_size = calloc(n, sizeof(size_t));
    *uncompressed_size = calloc(n, sizeof(size_t));
    *timestamps = calloc(n, sizeof(time_t));
    if (!*files || !*compressed_size || !*uncompressed_size) {
        status = -1; goto out;
    }

    for (i = 0; i < n; ++i) {
        size_t l;
        if (!mz_zip_reader_file_stat(&zip_archive, i, &info)) {
	    // Cannot get information about zip archive;
	    status = -1; goto out;
	}

	l = strlen(info.m_filename);
	if (l >= MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE) {
	  info.m_filename[MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE - 1] = '0';
	}
	(*files)[i] = strdup(info.m_filename);
	if (!(*files)[i]) { status = -1; goto out; }
	(*compressed_size)[i] = info.m_comp_size;
	(*uncompressed_size)[i] = info.m_uncomp_size;
	(*timestamps)[i] = info.m_time;
    }

 out:
    if (!mz_zip_reader_end(&zip_archive)) {
        // Cannot end zip reader
        status = -1;
    }

    if (status != 0) {
        if (*files) {
	    for (i = 0; i < n; ++i) if ((*files)[i]) free((*files)[i]);
	    free(*files);
	}
	if (*compressed_size) free(*compressed_size);
	if (*uncompressed_size) free(*uncompressed_size);
	*files = 0;
	*compressed_size = 0;
	*uncompressed_size = 0;
    }

    return status;
}
