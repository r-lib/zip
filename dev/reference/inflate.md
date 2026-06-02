# Uncompress a raw GZIP stream

Uncompress a raw GZIP stream

## Usage

``` r
inflate(buffer, pos = 1L, size = NULL)
```

## Arguments

- buffer:

  Raw vector, containing the data to uncompress.

- pos:

  Start position of data to uncompress in `buffer`.

- size:

  Uncompressed size estimate, or `NULL`. If not given, or too small, the
  output buffer is resized multiple times.

## Value

Named list with three entries:

- `output`: raw vector, the uncompressed data,

- `bytes_read`: number of bytes used from `buffer`,

- `bytes_written`: number of bytes written to the output buffer.

## See also

[`base::memDecompress()`](https://rdrr.io/r/base/memCompress.html) does
the same with `type = "gzip"`, but it does not tell you the number of
bytes read from the input.

## Examples

``` r
data_gz <- deflate(charToRaw("Hello world!"))
inflate(data_gz$output)
#> $output
#>  [1] 48 65 6c 6c 6f 20 77 6f 72 6c 64 21
#> 
#> $bytes_read
#> [1] 24
#> 
#> $bytes_written
#> [1] 12
#> 
```
