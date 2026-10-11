#!/usr/bin/env bash
# Runs docs-toc.sh on a small export with every awkward case in it and compares the whole table with the expected
# one, so any change in what counts as a heading or where a section ends fails here.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

toc="$(cd "$(dirname "$0")" && pwd)/docs-toc.sh"
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
  "$shell" "$toc" "$@" >"$root/out" 2>/dev/null || status=$?
  if [ "$status" -ne "$want_status" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want_status" "$status"
    failures=$((failures + 1))
  elif [ "$(cat "$root/out")" != "$want_output" ]; then
    printf 'FAIL %s: unexpected table\n' "$name"
    diff <(printf '%s\n' "$want_output") "$root/out" | sed 's/^/  /'
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

# Line numbers are given on the right; the expected table refers to them.
cat >"$root/export.txt" <<'EOF'
# First page
Source: https://code.claude.com/docs/en/first

Intro text.

## Setup
```bash
# a comment, not a heading
```
### Nested

````markdown
```
## inside a four-backtick fence
```
````
## Setup
  ```yaml
  # indented fence
  ```
<h4 id="html-heading">
  HTML heading
</h4>
Text under it.
## Unclosed
```
# Second page
Source: https://code.claude.com/docs/en/nested/second

## After an unclosed fence
EOF
# Lines: 1 First page, 6 Setup, 10 Nested, 17 Setup (2), 21 HTML heading (multi-line), 25 Unclosed,
# 27 Second page, 30 After an unclosed fence. The file has 30 lines.

tab=$'\t'
expected="first${tab}1${tab}First page${tab}1${tab}5${tab}26
first${tab}2${tab}Setup${tab}6${tab}9${tab}16
first${tab}3${tab}Nested${tab}10${tab}16${tab}16
first${tab}2${tab}Setup (2)${tab}17${tab}20${tab}24
first${tab}4${tab}HTML heading${tab}21${tab}24${tab}24
first${tab}2${tab}Unclosed${tab}25${tab}26${tab}26
nested/second${tab}1${tab}Second page${tab}27${tab}29${tab}30
nested/second${tab}2${tab}After an unclosed fence${tab}30${tab}30${tab}30"

expect 'full table' 0 "$expected" "$root/export.txt"

printf 'No pages here.\n# A title with no Source line\n' >"$root/empty.txt"
expect 'file with no pages' 1 '' "$root/empty.txt"
expect 'missing file' 2 '' "$root/missing.txt"
expect 'no arguments' 2 ''

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
