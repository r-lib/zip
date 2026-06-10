#!/bin/sh
# Regenerate the ZIP64 test fixtures in this directory.
#
# Two flavours of ZIP64 are exercised:
#
#   zip64.zip        - a real ZIP64 archive with a ZIP64 End of Central
#                      Directory record + locator. Info-ZIP's `-fz` sets the
#                      classic EOCD cd_offset field to the 0xFFFFFFFF sentinel,
#                      so reading it requires following the ZIP64 EOCD locator.
#                      Used by the HTTP range-request reader tests (R parser).
#                      NOTE: the bundled miniz reader rejects Info-ZIP's forced
#                      ZIP64 encoding, so this file is only used over HTTP.
#
#   zip64-extra.zip  - a classic EOCD archive whose entries carry ZIP64
#                      extended information extra fields (Python's
#                      force_zip64=True). Read by both the local (miniz) reader
#                      and the HTTP reader.
set -e
cd "$(dirname "$0")"

# --- zip64.zip : forced ZIP64 EOCD record (Info-ZIP) ---
work=$(mktemp -d 2>/dev/null || echo ./.z64build)
mkdir -p "$work/src/dir"
printf 'file1\n'  > "$work/src/file1"
printf 'file11\n' > "$work/src/file11"
printf 'file2\n'  > "$work/src/dir/file2"
printf 'file3\n'  > "$work/src/dir/file3"
( cd "$work" && zip -fz -r -X zip64.zip src >/dev/null )
cp "$work/zip64.zip" zip64.zip
rm -rf "$work"

# --- zip64-extra.zip : per-entry ZIP64 extended info fields (Python) ---
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('zip64-extra.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for name, content in [
        ('src/file1', 'file1\n'), ('src/file11', 'file11\n'),
        ('src/dir/file2', 'file2\n'), ('src/dir/file3', 'file3\n'),
    ]:
        with z.open(name, 'w', force_zip64=True) as f:
            f.write(content.encode())
PY
