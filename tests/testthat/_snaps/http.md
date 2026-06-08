# zip_list works with range request server

    Code
      zip_list_snapshot(url, za$ex)
    Output
                filename compressed_size uncompressed_size permissions    crc32 offset      type
      1          <root>/               0                 0         755 00000000 <offset> directory
      2      <root>/dir/               0                 0         755 00000000 <offset> directory
      3 <root>/dir/file2              11                 6         644 c904a4c7 <offset>      file
      4 <root>/dir/file3              11                 6         644 d01f9586 <offset>      file
      5     <root>/file1              11                 6         644 e229f704 <offset>      file
      6    <root>/file11              12                 7         644 09ea0445 <offset>      file

# unzip works with range request server

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# unzip extracts specific files with range request server

    Code
      extracted_tree(exdir, za$ex)
    Output
                path contents
      1 <root>/file1    file1

# zip_list falls back to full download when ranges unsupported

    Code
      zip_list_snapshot(url, za$ex)
    Condition
      Warning in `warn_no_range()`:
      Server '127.0.0.1' does not support HTTP range requests, downloading the whole file.
    Output
                filename compressed_size uncompressed_size permissions    crc32 offset      type
      1          <root>/               0                 0         755 00000000 <offset> directory
      2      <root>/dir/               0                 0         755 00000000 <offset> directory
      3 <root>/dir/file2              11                 6         644 c904a4c7 <offset>      file
      4 <root>/dir/file3              11                 6         644 d01f9586 <offset>      file
      5     <root>/file1              11                 6         644 e229f704 <offset>      file
      6    <root>/file11              12                 7         644 09ea0445 <offset>      file

# zip_list recovers when an oversized suffix range gives 416

    Code
      zip_list_snapshot(url, za$ex)
    Output
                filename compressed_size uncompressed_size permissions    crc32 offset      type
      1          <root>/               0                 0         755 00000000 <offset> directory
      2      <root>/dir/               0                 0         755 00000000 <offset> directory
      3 <root>/dir/file2              11                 6         644 c904a4c7 <offset>      file
      4 <root>/dir/file3              11                 6         644 d01f9586 <offset>      file
      5     <root>/file1              11                 6         644 e229f704 <offset>      file
      6    <root>/file11              12                 7         644 09ea0445 <offset>      file

# unzip recovers when an oversized suffix range gives 416

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# unzip falls back to full download when ranges unsupported

    Code
      unzip(url, exdir = exdir)
    Condition
      Warning in `warn_no_range()`:
      Server '127.0.0.1' does not support HTTP range requests, downloading the whole file.

---

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# unzip falls back to full download per entry when ranges drop out

    Code
      unzip(url, exdir = exdir)
    Condition
      Warning in `warn_no_range()`:
      Server '127.0.0.1' does not support HTTP range requests, downloading the whole file.

---

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# unzip fetches data separately when entry range is truncated

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# zip_list reads a ZIP64 EOCD archive over range requests

    Code
      zip_list_snapshot(url, za$ex)
    Output
                filename compressed_size uncompressed_size permissions    crc32 offset type
      1 <root>/dir/file2              11                 6         644 c904a4c7 <offset> file
      2 <root>/dir/file3              11                 6         644 d01f9586 <offset> file
      3     <root>/file1              11                 6         644 e229f704 <offset> file
      4    <root>/file11              12                 7         644 09ea0445 <offset> file

# reads a real ZIP64 EOCD-record archive over range requests

    Code
      zip_list_snapshot(url, sort = TRUE)
    Output
             filename compressed_size uncompressed_size permissions    crc32 offset      type
      1          src/               0                 0         755 00000000 <offset> directory
      2      src/dir/               0                 0         755 00000000 <offset> directory
      3 src/dir/file2               6                 6         644 c904a4c7 <offset>      file
      4 src/dir/file3               6                 6         644 d01f9586 <offset>      file
      5     src/file1               6                 6         644 e229f704 <offset>      file
      6    src/file11               7                 7         644 09ea0445 <offset>      file

---

    Code
      extracted_tree(exdir)
    Output
                 path contents
      1 src/dir/file2    file2
      2 src/dir/file3    file3
      3     src/file1    file1
      4    src/file11   file11

# unzip reads a ZIP64 EOCD archive over range requests

    Code
      extracted_tree(exdir, za$ex)
    Output
                    path contents
      1 <root>/dir/file2    file2
      2 <root>/dir/file3    file3
      3     <root>/file1    file1
      4    <root>/file11   file11

# unzip with junkpaths works with range request server

    Code
      extracted_tree(exdir)
    Output
          path contents
      1  file1    file1
      2 file11   file11
      3  file2    file2
      4  file3    file3

