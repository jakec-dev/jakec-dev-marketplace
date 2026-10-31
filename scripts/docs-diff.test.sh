#!/usr/bin/env bash
# Runs docs-diff.sh on two small fingerprint files and two ledgers and compares the whole report with the expected
# one, so any change in what counts as changed, added or removed, or in how ledger rows are joined, fails here.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

diff_script="$(cd "$(dirname "$0")" && pwd)/docs-diff.sh"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0

expect() {
  local name=$1 want_status=$2 want_output=$3 status=0
  shift 3
  cases=$((cases + 1))
  "$shell" "$diff_script" "$@" >"$root/out" 2>/dev/null || status=$?
  if [ "$status" -ne "$want_status" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want_status" "$status"
    failures=$((failures + 1))
  elif [ "$(cat "$root/out")" != "$want_output" ]; then
    printf 'FAIL %s: unexpected report\n' "$name"
    diff <(printf '%s\n' "$want_output") "$root/out" | sed 's/^/  /'
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

printf 'hooks\tStop\taaa\nhooks\tSetup\tbbb\nhooks\tGone\tccc\nskills\tSame\tddd\n' >"$root/old.tsv"
printf 'hooks\tStop\tAAA\nhooks\tSetup\tbbb\nhooks\tNew\teee\nskills\tSame\tddd\n' >"$root/new.tsv"
mkdir "$root/ledger"
printf 'page\theading\tdecision\tfile\treason\nhooks\tStop\tincluded\tevents.md\t\nhooks\tGone\texcluded\t\trepeats Stop\n' \
  >"$root/ledger/hooks.tsv"
printf 'page\theading\tdecision\tfile\treason\nhooks\tStop\tincluded\twrite-hooks.md\tthe loop sentence\n' \
  >"$root/ledger/guidance.tsv"

expect 'changed, added and removed, joined with every ledger row' 0 "$(printf '%s\n' \
  $'removed\thooks\tGone\thooks\texcluded\t' \
  $'added\thooks\tNew\t\t\t' \
  $'changed\thooks\tStop\tguidance\tincluded\twrite-hooks.md' \
  $'changed\thooks\tStop\thooks\tincluded\tevents.md')" \
  "$root/old.tsv" "$root/new.tsv" "$root/ledger/hooks.tsv" "$root/ledger/guidance.tsv"

expect 'without ledgers, every row has empty ledger columns' 0 "$(printf '%s\n' \
  $'removed\thooks\tGone\t\t\t' \
  $'added\thooks\tNew\t\t\t' \
  $'changed\thooks\tStop\t\t\t')" \
  "$root/old.tsv" "$root/new.tsv"

expect 'identical fingerprints report nothing' 0 '' "$root/old.tsv" "$root/old.tsv"
expect 'a missing ledger is a usage error' 2 '' "$root/old.tsv" "$root/new.tsv" "$root/ledger/none.tsv"
expect 'one fingerprint file is a usage error' 2 '' "$root/old.tsv"

printf '%s of %s cases passed\n' "$((cases - failures))" "$cases"
[ "$failures" -eq 0 ]
