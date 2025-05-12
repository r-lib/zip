# symlinks

    Code
      zip_list(zf)
    Output
      # A data frame: 3 x 8
        filename compressed_size uncompressed_size timestamp           permissions crc32     offset type     
        <chr>              <dbl>             <dbl> <dttm>              <octmode>   <hexmode>  <dbl> <chr>    
      1 a/                     0                 0 2025-05-11 20:27:28 755         00000000       0 directory
      2 a/foo                  4                 4 2025-05-11 20:27:24 644         7e3265a8      60 file     
      3 a/bar                  3                 3 2025-05-11 20:27:28 755         8c736521     127 symlink  

