#!/usr/bin/env bash
# shellcheck disable=SC2016 # Backticks in the fixtures are literal Markdown, not command substitution.
# Runs knowledge-index.sh on a small knowledge directory and compares the whole Topics section with the expected one,
# so a change in ordering, wrapping or which headings count fails here.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/knowledge-index.sh"
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
  "$shell" "$script" "$@" >"$root/out" 2>/dev/null || status=$?
  if [ "$status" -ne "$want_status" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want_status" "$status"
    failures=$((failures + 1))
  elif [ "$(cat "$root/out")" != "$want_output" ]; then
    printf 'FAIL %s: unexpected output\n' "$name"
    diff <(printf '%s\n' "$want_output") "$root/out" | sed 's/^/  /'
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

mkdir -p "$root/rules"
cat >"$root/rules/second.md" <<'EOF'
# Second

## Contents

- Alpha

## Alpha

```markdown
## Not a heading, inside a fence
```

## Not stated by the documentation
EOF
printf '# First\n\n## Only section\n' >"$root/rules/first.md"
long=$(printf 'word %.0s' {1..30})
cat >"$root/topics.md" <<EOF
# Rules topics

- \`first.md\`: the first task, listed first although its name sorts first anyway
- \`second.md\`: a task whose description is long enough to wrap: ${long}
  and carries on here
EOF

expected='## Topics

- [first.md](first.md): the first task, listed first although its name sorts first anyway
  - Only section

- [second.md](second.md): a task whose description is long enough to wrap: word word word word word word word word word
  word word word word word word word word word word word word word word word word word word word word word and carries
  on here
  - Alpha
  - Not stated by the documentation'
expect 'topics in order, wrapped, fences and contents skipped' 0 "$expected" "$root/rules" "$root/topics.md"

printf -- '- `missing.md`: a task\n' >"$root/missing-topics.md"
expect 'listed file missing' 1 '## Topics' "$root/rules" "$root/missing-topics.md"
expect 'no arguments' 2 ''

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
