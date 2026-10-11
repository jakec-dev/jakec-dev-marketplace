#!/usr/bin/env bash
# Lists the sections of Claude Code's documentation export whose own text matches a pattern, one tab-separated row
# per section, most matches first:
#
#   matches  page  level  heading  start  end
#
# `start` and `end` are the section's own lines, from its heading to the line before the next heading of any level,
# as scripts/docs-toc.sh prints them. A match in a subsection counts for the subsection, not its parent.
#
# Usage: docs-find.sh <llms-full.txt> <toc.tsv> <extended-regex> [<also-regex>]
# Patterns are matched case-insensitively. With <also-regex>, a section is listed only if its own text also matches
# that, such as the tool type's name. Exit status: 0 when any section matches, 1 when none does, 2 on a usage error.

set -euo pipefail

if [ $# -lt 3 ] || [ $# -gt 4 ] || [ ! -f "$1" ] || [ ! -f "$2" ] || [ -z "$3" ]; then
  echo 'usage: docs-find.sh <llms-full.txt> <toc.tsv> <extended-regex> [<also-regex>]' >&2
  exit 2
fi

result=$(
  grep -n -i -E -e "$3" "$1" | cut -d : -f 1 | awk -F '\t' '
    NR == FNR { n++; page[n] = $1; level[n] = $2; head[n] = $3; start[n] = $4; own[n] = $5; next }
    {
      # Sections are in line order, so a binary search finds the one whose own range holds the line.
      lo = 1; hi = n
      while (lo < hi) { mid = int((lo + hi + 1) / 2); if (start[mid] <= $1) lo = mid; else hi = mid - 1 }
      if (start[lo] <= $1 && $1 <= own[lo]) hits[lo]++
    }
    END { for (i in hits) print hits[i] "\t" page[i] "\t" level[i] "\t" head[i] "\t" start[i] "\t" own[i] }
  ' "$2" - | sort -t "$(printf '\t')" -k1,1nr -k5,5n
)
# Keeps only the sections whose own lines also match the second pattern.
if [ $# -eq 4 ] && [ -n "$result" ]; then
  result=$(printf '%s\n' "$result" | while IFS=$'\t' read -r hits page level head start end; do
    if sed -n "${start},${end}p" "$1" | grep -q -i -E -e "$4"; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$hits" "$page" "$level" "$head" "$start" "$end"
    fi
  done)
fi
[ -n "$result" ] || exit 1
printf '%s\n' "$result"
