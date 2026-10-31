#!/usr/bin/env bash
# Compares two fingerprint files from scripts/docs-fingerprint.sh and prints each section that changed, was added
# or was removed, with every ledger row that records it, one tab-separated row each:
#
#   status  page  heading  type  decision  file
#
# `status` is changed, added or removed. `type` is the ledger's name without .tsv, such as hooks or guidance, and
# `decision` and `file` are that row's columns. A section no ledger records gets one row with the last three columns
# empty. Rows are sorted by page and heading.
#
# What each row asks for: a changed included row means its file may now state something the documentation no longer
# says; a changed excluded row means the reason for leaving it out may no longer hold; a removed row means the ledger
# names a section that no longer exists; an added section is a candidate no ledger has seen.
#
# Usage: docs-diff.sh <old-fingerprints.tsv> <new-fingerprints.tsv> [<ledger.tsv>...]
# Exit status: 0 on success, 2 on a usage error.

set -euo pipefail

if [ $# -lt 2 ] || [ ! -f "$1" ] || [ ! -f "$2" ]; then
  echo 'usage: docs-diff.sh <old-fingerprints.tsv> <new-fingerprints.tsv> [<ledger.tsv>...]' >&2
  exit 2
fi
for ledger in "${@:3}"; do
  if [ ! -f "$ledger" ]; then
    echo "$ledger: no such ledger" >&2
    exit 2
  fi
done

awk -F '\t' '
  FNR == 1 { file++; type = FILENAME; sub(/.*\//, "", type); sub(/\.tsv$/, "", type) }
  file == 1 { old[$1 "\t" $2] = $3; next }
  file == 2 { new[$1 "\t" $2] = $3; next }
  FNR == 1 { next }
  { key = $1 "\t" $2; rows[key] = rows[key] "\n" type "\t" $3 "\t" $4 }
  function report(status, key,    parts, count, i) {
    if (!(key in rows)) { print status "\t" key "\t\t\t"; return }
    count = split(substr(rows[key], 2), parts, "\n")
    for (i = 1; i <= count; i++) print status "\t" key "\t" parts[i]
  }
  END {
    for (key in new) {
      if (!(key in old)) report("added", key)
      else if (old[key] != new[key]) report("changed", key)
    }
    for (key in old) if (!(key in new)) report("removed", key)
  }
' "$1" "$2" "${@:3}" | sort -t "$(printf '\t')" -k2,2 -k3,3 -k1,1 -k4,4
