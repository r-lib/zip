/*
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#pragma once
#ifndef ZIP_H
#define ZIP_H

#include <string.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MAX_PATH
#define MAX_PATH 32767 /* # chars in a path name including NULL */
#endif

#define ZIP_DEFAULT_COMPRESSION_LEVEL 6

/*
  This data structure is used throughout the library to represent zip archive
  - forward declaration.
*/
struct zip_t;

extern int zip_list(const char *zipname, size_t *num, char ***files,
		    size_t **compressed_size, size_t **uncompressed_size,
		    time_t **timestamps);

#ifdef __cplusplus
}
#endif

#endif
