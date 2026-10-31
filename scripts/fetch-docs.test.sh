#!/usr/bin/env bash
# Runs fetch-docs.sh against local files through DOCS_URL, so no test touches the network, and checks that a failed
# or empty fetch leaves the previous copy in place.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

fetch="$(cd "$(dirname "$0")" && pwd)/fetch-docs.sh"
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

printf '# Page\nSource: https://code.claude.com/docs/en/page\n\nText.\n' >"$root/good.txt"
printf '<html>Not found</html>\n' >"$root/bad.txt"

status=0
DOCS_URL="file://$root/good.txt" "$shell" "$fetch" "$root/out.txt" 2>/dev/null || status=$?
[ "$status" = 0 ] && cmp -s "$root/good.txt" "$root/out.txt" && ok=yes || ok=no
check 'a fetch with pages writes the file' "$ok"

status=0
DOCS_URL="file://$root/bad.txt" "$shell" "$fetch" "$root/out.txt" 2>/dev/null || status=$?
[ "$status" = 1 ] && cmp -s "$root/good.txt" "$root/out.txt" && ok=yes || ok=no
check 'a result with no pages fails and keeps the previous copy' "$ok"

status=0
DOCS_URL="file://$root/missing.txt" "$shell" "$fetch" "$root/out.txt" 2>/dev/null || status=$?
[ "$status" = 1 ] && cmp -s "$root/good.txt" "$root/out.txt" && ok=yes || ok=no
check 'a failed fetch keeps the previous copy' "$ok"

[ "$(find "$root" -name 'out.txt.*' | wc -l | tr -d ' ')" = 0 ] && ok=yes || ok=no
check 'no temporary file is left behind' "$ok"

status=0
"$shell" "$fetch" 2>/dev/null || status=$?
[ "$status" = 2 ] && ok=yes || ok=no
check 'a missing argument is a usage error' "$ok"

printf '%s of %s cases passed\n' "$((cases - failures))" "$cases"
[ "$failures" -eq 0 ]
