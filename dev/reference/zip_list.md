# List Files in a 'zip' Archive

List Files in a 'zip' Archive

## Usage

``` r
zip_list(zipfile)
```

## Arguments

- zipfile:

  Path to an existing ZIP file.

## Value

A data frame with columns: `filename`, `compressed_size`,
`uncompressed_size`, `timestamp`, `permissions`, `crc32`, `offset` and
`type`. `type` is one of `file`, `block_device`, `character_device`,
`directory`, `FIFO`, `symlink` or `socket`.

## Details

Note that `crc32` is formatted using
[`as.hexmode()`](https://rdrr.io/r/base/hexmode.html). `offset` refers
to the start of the local zip header for each entry. Following the
approach of [`seek()`](https://rdrr.io/r/base/seek.html) it is stored as
a `numeric` rather than an `integer` vector and can therefore represent
values up to `2^53-1` (9 PB).
