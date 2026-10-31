#!/usr/bin/env bash
# Runs docs-fingerprint.sh on a small export and checks that each row's hash covers exactly its section's own text:
# a change in one section changes only that section's row.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0

check() {
  local name=$1 ok=$2
  cases=$((cases + 1))
  if [ "$ok" = yes ]; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name"
    failures=$((failures + 1))
  fi
}

hash_of() { printf '%s' "$1" | shasum -a 256 | cut -c 1-64; }

cat >"$root/export.txt" <<'EOF'
# First page
Source: https://code.claude.com/docs/en/first

Intro text.

## Setup

Setup text.
### Nested
Nested text.
## Empty
EOF

"$shell" "$here/docs-toc.sh" "$root/export.txt" >"$root/toc.tsv"
"$shell" "$here/docs-fingerprint.sh" "$root/export.txt" "$root/toc.tsv" >"$root/before.tsv"

rows=$(wc -l <"$root/before.tsv" | tr -d ' ')
[ "$rows" = 4 ] && ok=yes || ok=no
check 'one row per section' "$ok"

want=$(printf 'first\tSetup\t%s' "$(hash_of $'\nSetup text.\n')")
[ "$(sed -n 2p "$root/before.tsv")" = "$want" ] && ok=yes || ok=no
check "hash covers the section's own text, not its subsection" "$ok"

want=$(printf 'first\tEmpty\t%s' "$(hash_of '')")
[ "$(sed -n 4p "$root/before.tsv")" = "$want" ] && ok=yes || ok=no
check 'a heading with no text hashes the empty string' "$ok"

sed 's/^Nested text\.$/Nested text, edited./' "$root/export.txt" >"$root/edited.txt"
"$shell" "$here/docs-toc.sh" "$root/edited.txt" >"$root/toc2.tsv"
"$shell" "$here/docs-fingerprint.sh" "$root/edited.txt" "$root/toc2.tsv" >"$root/after.tsv"
changed=$(diff "$root/before.tsv" "$root/after.tsv" | grep -c '^>' || true)
grep -q "^first	Nested	" <(diff "$root/before.tsv" "$root/after.tsv" | sed -n 's/^> //p') && [ "$changed" = 1 ] &&
  ok=yes || ok=no
check 'an edit changes only its own section' "$ok"

status=0
"$shell" "$here/docs-fingerprint.sh" "$root/export.txt" 2>/dev/null || status=$?
[ "$status" = 2 ] && ok=yes || ok=no
check 'a missing argument is a usage error' "$ok"

: >"$root/empty.tsv"
status=0
"$shell" "$here/docs-fingerprint.sh" "$root/export.txt" "$root/empty.tsv" 2>/dev/null || status=$?
[ "$status" = 1 ] && ok=yes || ok=no
check 'an empty table of contents fails' "$ok"

printf '%s of %s cases passed\n' "$((cases - failures))" "$cases"
[ "$failures" -eq 0 ]
