#!/bin/sh
# Regenerate the encrypted ZIP test fixtures in this directory.
#
# These archives are produced by *external* tools (7-Zip and Info-ZIP), not by
# this package, so they exercise the inbound interop direction: the package's
# reader must decrypt what other implementations encrypt.
#
# All fixtures use the password  secret  unless noted otherwise. Each archive
# contains the same three entries:
#
#   a.txt        - small, stored (too small to benefit from deflate)
#   sub/b.txt    - small, stored, in a subdirectory
#   big.txt      - highly compressible, so it is deflated then encrypted
#
#   aes256.zip        - 7-Zip, WinZip AES-256 (AE-2)
#   aes192.zip        - 7-Zip, WinZip AES-192 (AE-2)
#   aes128.zip        - 7-Zip, WinZip AES-128 (AE-2)
#   zipcrypto.zip     - Info-ZIP, legacy traditional PKWARE (ZipCrypto) cipher
#
# (The non-ASCII / UTF-8 password contract is exercised by a writer+reader
# round-trip test rather than a fixture: the 7-Zip CLI rejects a non-ASCII
# password argument with E_INVALIDARG.)
#
# Requires: 7zz (brew install sevenzip) and zip (Info-ZIP).
set -e
cd "$(dirname "$0")"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
need 7zz
need zip

work=$(mktemp -d 2>/dev/null || echo ./.encbuild)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/sub"
printf 'first fixture file\n'     > "$work/a.txt"
printf 'second file in subdir\n'  > "$work/sub/b.txt"
# big.txt: compressible so the entry is deflated (real method 8) before
# encryption, exercising the decrypt-then-inflate path.
i=0; : > "$work/big.txt"
while [ "$i" -lt 400 ]; do
  printf 'The quick brown fox jumps over the lazy dog. 0123456789\n' >> "$work/big.txt"
  i=$((i + 1))
done

mkaes() {  # strength password outfile
  rm -f "$work/$3"
  ( cd "$work" && 7zz a -tzip -p"$2" -mem="AES$1" "$3" a.txt sub/b.txt big.txt >/dev/null )
  cp "$work/$3" "$3"
}

mkaes 256 secret  aes256.zip
mkaes 192 secret  aes192.zip
mkaes 128 secret  aes128.zip

# Legacy traditional PKWARE encryption (ZipCrypto), via Info-ZIP.
rm -f zipcrypto.zip
( cd "$work" && zip -q -P secret zipcrypto.zip a.txt sub/b.txt big.txt )
cp "$work/zipcrypto.zip" zipcrypto.zip

echo "Wrote: aes256.zip aes192.zip aes128.zip zipcrypto.zip"
