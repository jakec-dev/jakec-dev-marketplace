#!/usr/bin/env bash
# Feeds check-commit-msg.sh one message per case and asserts its exit status, so a rule that has
# stopped firing fails here instead of letting every message through.
# BASH_UNDER_TEST picks the shell that runs the check, such as macOS's /bin/bash 3.2.

set -euo pipefail

check="$(cd "$(dirname "$0")" && pwd)/check-commit-msg.sh"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0

# Writes the message to a file, runs the check on it and compares the exit status with the expected one.
expect() {
  local want=$1 name=$2 message=$3 status=0
  cases=$((cases + 1))
  printf '%s' "$message" >"$root/message"
  "$shell" "$check" "$root/message" >"$root/out" 2>&1 || status=$?
  if [ "$status" -ne "$want" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want" "$status"
    sed 's/^/  /' "$root/out"
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

nl=$'\n'
scissors='# ------------------------ >8 ------------------------'
template="# Please enter the commit message${nl}docs: add README${nl}# On branch master${nl}"

expect 0 'type and description' "chore: add MIT license$nl"
expect 0 'type with scope' "feat(agent-setup): add the write skill$nl"
expect 0 'breaking change mark' "feat(marketplace)!: rename the marketplace$nl"
expect 0 'body and footer' "fix(ci): pin checkout${nl}${nl}Pinned by SHA.${nl}${nl}Closes #12$nl"
expect 0 'comments and scissors dropped' "${template}${scissors}${nl}feat bad header below the scissors$nl"
expect 0 'leading blank lines dropped' "${nl}${nl}ci: add workflow$nl"
expect 0 'header of exactly 72 characters' "chore: $(printf 'x%.0s' {1..65})$nl"
expect 0 'git merge message' "Merge branch 'feat/write-skill'$nl"
expect 0 'git revert message' "Revert \"feat: add the write skill\"$nl"
expect 0 'fixup commit' "fixup! feat: add the write skill$nl"
expect 0 'squash commit' "squash! feat: add the write skill$nl"
expect 0 'message without a final newline' 'test: cover the hook'

expect 1 'no type' "add the write skill$nl"
expect 1 'unknown type' "feature: add the write skill$nl"
expect 1 'type outside the allowed list' "perf: speed up the hook$nl"
expect 1 'capitalised type' "Feat: add the write skill$nl"
expect 1 'no space after the colon' "feat:add the write skill$nl"
expect 1 'empty description' "feat: $nl"
expect 1 'empty scope' "feat(): add the write skill$nl"
expect 1 'uppercase scope' "feat(Agent-Setup): add the write skill$nl"
expect 1 'issue key before the type' "[GH-12] feat: add the write skill$nl"
expect 1 'header of 73 characters' "chore: $(printf 'x%.0s' {1..66})$nl"
expect 1 'header ending in a full stop' "docs: add README.$nl"
expect 1 'body without a blank line' "fix: pin checkout${nl}Pinned by SHA.$nl"
expect 1 'empty message' "$nl"
expect 1 'only comments' "# Please enter the commit message$nl"

# Usage errors exit 2, which a hook treats as a failure too.
cases=$((cases + 1))
status=0
"$shell" "$check" "$root/missing" >/dev/null 2>&1 || status=$?
if [ "$status" -eq 2 ]; then echo 'ok   missing file'; else
  echo "FAIL missing file: want exit 2, got $status"
  failures=$((failures + 1))
fi

cases=$((cases + 1))
status=0
printf 'docs: add README\n' | "$shell" "$check" - >/dev/null 2>&1 || status=$?
if [ "$status" -eq 0 ]; then echo 'ok   standard input'; else
  echo "FAIL standard input: want exit 0, got $status"
  failures=$((failures + 1))
fi

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
