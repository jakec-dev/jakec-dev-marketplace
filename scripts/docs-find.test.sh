#!/usr/bin/env bash
# Runs docs-find.sh on a small export and its table of contents and compares the rows with the expected ones, so a
# change in how matches are assigned to sections fails here.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0

# Compares a run's output and exit status with the expected ones.
expect() {
  local name=$1 want_status=$2 want_output=$3 status=0
  shift 3
  cases=$((cases + 1))
  "$shell" "$dir/docs-find.sh" "$@" >"$root/out" 2>/dev/null || status=$?
  if [ "$status" -ne "$want_status" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want_status" "$status"
    failures=$((failures + 1))
  elif [ "$(cat "$root/out")" != "$want_output" ]; then
    printf 'FAIL %s: unexpected rows\n' "$name"
    diff <(printf '%s\n' "$want_output") "$root/out" | sed 's/^/  /'
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

cat >"$root/export.txt" <<'EOF'
# First page
Source: https://code.claude.com/docs/en/first

Intro mentions a Widget.
## Parent
Parent text, no match.
### Child
A widget here.
And WIDGET again.
# Second page
Source: https://code.claude.com/docs/en/second

## Other
One widget.
## Widget list
EOF
"$shell" "$dir/docs-toc.sh" "$root/export.txt" >"$root/toc.tsv"

tab=$'\t'
expect 'matches counted per own section, most first' 0 "2${tab}first${tab}3${tab}Child${tab}7${tab}9
1${tab}first${tab}1${tab}First page${tab}1${tab}4
1${tab}second${tab}2${tab}Other${tab}13${tab}14
1${tab}second${tab}2${tab}Widget list${tab}15${tab}15" "$root/export.txt" "$root/toc.tsv" 'widget'
expect 'match in a parent only' 0 "1${tab}first${tab}2${tab}Parent${tab}5${tab}6" \
  "$root/export.txt" "$root/toc.tsv" 'no match'
expect 'no section matches' 1 '' "$root/export.txt" "$root/toc.tsv" 'absent'
expect 'missing pattern' 2 '' "$root/export.txt" "$root/toc.tsv" ''

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
