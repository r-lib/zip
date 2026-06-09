# List Files in a 'zip' Archive

List Files in a 'zip' Archive

## Usage

``` r
zip_list(zipfile, encoding = NULL)
```

## Arguments

- zipfile:

  Path to an existing ZIP file.

- encoding:

  Encoding to use for entry filenames. ZIP files signal UTF-8 filenames
  via a flag in each entry; those are always decoded as UTF-8 regardless
  of `encoding`. For entries without that flag, `encoding` is used;
  `NULL` (the default) falls back to IBM CP437, which is what the ZIP
  specification prescribes for legacy entries. The value is passed to
  [`iconv()`](https://rdrr.io/r/base/iconv.html).

## Value

A data frame with columns: `filename`, `compressed_size`,
`uncompressed_size`, `timestamp`, `permissions`, `crc32`, `offset`,
`type` and `encryption`. `type` is one of `file`, `block_device`,
`character_device`, `directory`, `FIFO`, `symlink` or `socket`.
`encryption` is one of `none`, `aes128`, `aes192`, `aes256`,
`zipcrypto`, or `NA` if encrypted but the scheme cannot be determined.

## Details

Note that `crc32` is formatted using
[`as.hexmode()`](https://rdrr.io/r/base/hexmode.html). `offset` refers
to the start of the local zip header for each entry. Following the
approach of [`seek()`](https://rdrr.io/r/base/seek.html) it is stored as
a `numeric` rather than an `integer` vector and can therefore represent
values up to `2^53-1` (9 PB).

## See also

Other zip/unzip functions:
[`unzip()`](https://r-lib.github.io/zip/dev/reference/unzip.md)
