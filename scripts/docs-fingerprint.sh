#!/usr/bin/env bash
# Prints a fingerprint for each section of a documentation export, one tab-separated row per section:
#
#   page  heading  sha256
#
# The hash covers the section's own text, the lines after its heading up to the `end` column of scripts/docs-toc.sh,
# so a change in a subsection changes only the subsection's row. Two fingerprint files made from two snapshots
# show which sections changed without keeping either snapshot; scripts/docs-diff.sh compares them.
#
# Usage: docs-fingerprint.sh <llms-full.txt> <toc.tsv>
#   <toc.tsv>  the output of scripts/docs-toc.sh for the same export
# Exit status: 0 on success, 1 when the table of contents is empty, 2 on a usage error.

set -euo pipefail

if [ $# -ne 2 ] || [ ! -f "$1" ] || [ ! -f "$2" ]; then
  echo 'usage: docs-fingerprint.sh <llms-full.txt> <toc.tsv>' >&2
  exit 2
fi
if [ ! -s "$2" ]; then
  echo "$2: empty table of contents" >&2
  exit 1
fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

# Writes each section's own text to a file named by its row number, zero-padded so that a glob lists them in row
# order. Rows are in document order and their own-text ranges don't overlap, so one pass over the export fills them.
awk -F '\t' -v dir="$dir" '
  function path(i) { return sprintf("%s/%06d", dir, i) }
  NR == FNR { n++; start[n] = $4; end[n] = $5; next }
  {
    while (i <= n && (i == 0 || FNR > end[i])) { if (i) close(path(i)); i++ }
    if (i <= n && FNR > start[i]) print > path(i)
  }
  END { for (j = 1; j <= n; j++) { printf "" >> path(j); close(path(j)) } }
' "$2" "$1"

paste <(cut -f 1,3 "$2") <(shasum -a 256 "$dir"/* | cut -c 1-64)
