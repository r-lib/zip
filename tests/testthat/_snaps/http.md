# zip_list works with range request server

    Code
      zip_list_snapshot(url, za$ex)
    Output
                filename compressed_size uncompressed_size permissions    crc32
      1          <root>/               0                 0         755 00000000
      2      <root>/dir/               0                 0         755 00000000
      3 <root>/dir/file2              11                 6         644 c904a4c7
      4 <root>/dir/file3              11                 6         644 d01f9586
      5     <root>/file1              11                 6         644 e229f704
      6    <root>/file11              12                 7         644 09ea0445
        offset      type
      1      0 directory
      2     52 directory
      3    108      file
      4    196      file
      5    284      file
      6    368      file

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
      # A data frame: 6 x 7
        filename      compressed_size uncompressed_size permissions crc32 offset type 
        <chr>                   <dbl>             <dbl> <octmode>   <hex>  <dbl> <chr>
      1 <root>/                     0                 0 755         0000~      0 file 
      2 <root>/dir/                 0                 0 755         0000~     52 file 
      3 <root>/dir/f~              11                 6 644         c904~    108 file 
      4 <root>/dir/f~              11                 6 644         d01f~    196 file 
      5 <root>/file1               11                 6 644         e229~    284 file 
      6 <root>/file11              12                 7 644         09ea~    368 file 

# zip_list recovers when an oversized suffix range gives 416

    Code
      zip_list_snapshot(url, za$ex)
    Output
      # A data frame: 6 x 7
        filename      compressed_size uncompressed_size permissions crc32 offset type 
        <chr>                   <dbl>             <dbl> <octmode>   <hex>  <dbl> <chr>
      1 <root>/                     0                 0 755         0000~      0 dire~
      2 <root>/dir/                 0                 0 755         0000~     50 dire~
      3 <root>/dir/f~              11                 6 644         c904~    104 file 
      4 <root>/dir/f~              11                 6 644         d01f~    190 file 
      5 <root>/file1               11                 6 644         e229~    276 file 
      6 <root>/file11              12                 7 644         09ea~    358 file 

# unzip recovers when an oversized suffix range gives 416

    Code
      extracted_tree(exdir, za$ex)
    Output
      # A data frame: 4 x 2
        path             contents
        <chr>            <chr>   
      1 <root>/dir/file2 file2   
      2 <root>/dir/file3 file3   
      3 <root>/file1     file1   
      4 <root>/file11    file11  

# unzip falls back to full download when ranges unsupported

    Code
      extracted_tree(exdir, za$ex)
    Output
      # A data frame: 4 x 2
        path             contents
        <chr>            <chr>   
      1 <root>/dir/file2 file2   
      2 <root>/dir/file3 file3   
      3 <root>/file1     file1   
      4 <root>/file11    file11  

# unzip falls back to full download per entry when ranges drop out

    Code
      extracted_tree(exdir, za$ex)
    Output
      # A data frame: 4 x 2
        path             contents
        <chr>            <chr>   
      1 <root>/dir/file2 file2   
      2 <root>/dir/file3 file3   
      3 <root>/file1     file1   
      4 <root>/file11    file11  

# unzip fetches data separately when entry range is truncated

    Code
      extracted_tree(exdir, za$ex)
    Output
      # A data frame: 4 x 2
        path             contents
        <chr>            <chr>   
      1 <root>/dir/file2 file2   
      2 <root>/dir/file3 file3   
      3 <root>/file1     file1   
      4 <root>/file11    file11  

# zip_list reads a ZIP64 EOCD archive over range requests

    Code
      zip_list_snapshot(url, za$ex)
    Output
      # A data frame: 4 x 7
        filename      compressed_size uncompressed_size permissions crc32 offset type 
        <chr>                   <dbl>             <dbl> <octmode>   <hex>  <dbl> <chr>
      1 <root>/dir/f~              11                 6 644         c904~      0 file 
      2 <root>/dir/f~              11                 6 644         d01f~     88 file 
      3 <root>/file1               11                 6 644         e229~    176 file 
      4 <root>/file11              12                 7 644         09ea~    260 file 

# reads a real ZIP64 EOCD-record archive over range requests

    Code
      zip_list_snapshot(url, sort = TRUE)
    Output
      # A data frame: 6 x 7
        filename      compressed_size uncompressed_size permissions crc32 offset type 
        <chr>                   <dbl>             <dbl> <octmode>   <hex>  <dbl> <chr>
      1 src/                        0                 0 755         0000~      0 dire~
      2 src/dir/                    0                 0 755         0000~    121 dire~
      3 src/dir/file2               6                 6 644         c904~    248 file 
      4 src/dir/file3               6                 6 644         d01f~    179 file 
      5 src/file1                   6                 6 644         e229~    317 file 
      6 src/file11                  7                 7 644         09ea~     54 file 

---

    Code
      extracted_tree(exdir)
    Output
      # A data frame: 4 x 2
        path          contents
        <chr>         <chr>   
      1 src/dir/file2 file2   
      2 src/dir/file3 file3   
      3 src/file1     file1   
      4 src/file11    file11  

# unzip reads a ZIP64 EOCD archive over range requests

    Code
      extracted_tree(exdir, za$ex)
    Output
      # A data frame: 4 x 2
        path             contents
        <chr>            <chr>   
      1 <root>/dir/file2 file2   
      2 <root>/dir/file3 file3   
      3 <root>/file1     file1   
      4 <root>/file11    file11  

# unzip with junkpaths works with range request server

    Code
      extracted_tree(exdir)
    Output
      # A data frame: 4 x 2
        path   contents
        <chr>  <chr>   
      1 file1  file1   
      2 file11 file11  
      3 file2  file2   
      4 file3  file3   

