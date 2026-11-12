#!/usr/bin/env bash
# Runs try-content.sh against a stub `claude` that writes what it finds in the checkout, so the arms, the hiding of
# the change from git, the check and the clean-up are tested without calling a model.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/try-content.sh"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0
check() {
  local name=$1
  shift
  cases=$((cases + 1))
  if "$@"; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name"
    failures=$((failures + 1))
  fi
}

# The stub records its arguments and what git status shows, writes styled.txt when the style rule is present, and
# calls the hello skill when that skill is present.
mkdir -p "$root/bin"
cat >"$root/bin/claude" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >stub-args.txt
git status --porcelain >stub-status.txt
if [ -f .claude/rules/style.md ]; then echo styled >styled.txt; fi
read="{\"type\":\"tool_use\",\"name\":\"Read\",\"input\":{\"file_path\":\"$PWD/src/a.ts\"}}"
echo "{\"type\":\"assistant\",\"message\":{\"content\":[$read]}}"
if [ -f .claude/skills/hello/SKILL.md ]; then
  echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"hello"}}]}}'
fi
echo '{"type":"result","total_cost_usd":0.01}'
SH
chmod +x "$root/bin/claude"
export PATH="$root/bin:$PATH"

repo="$root/repo"
mkdir -p "$repo/src"
echo 'export const a = 1' >"$repo/src/a.ts"
echo '# Project' >"$repo/CLAUDE.md"
git -C "$repo" init -q
git -C "$repo" add -A
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q -m init

run() {
  local status=0
  (cd "$repo" && "$shell" "$script" "$@") >"$root/output" 2>&1 || status=$?
  echo "$status" >"$root/status"
}
lacks() { ! grep -q "$1" "$2"; }
column() { awk -F '\t' -v arm="$2" -v col="$3" '$1 == arm { print $col }' "$1" | sort -u | paste -sd , -; }

spec="$root/add-spec"
mkdir -p "$spec"
echo 'Use the style.' >"$spec/style.md"
echo 'style.md .claude/rules/style.md' >"$spec/add.txt"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'test -f styled.txt' >"$spec/check.sh"
run -n 2 -j 2 "$spec" "$root/out-add"
check 'add: exits 0' [ "$(cat "$root/status")" = 0 ]
check 'add: the with-arm passes its check in both runs' [ "$(column "$root/out-add/results.tsv" with 3)" = pass ]
check 'add: the without-arm fails its check in both runs' [ "$(column "$root/out-add/results.tsv" without 3)" = fail ]
check 'add: the diff holds what Claude wrote' grep -q 'styled.txt' "$root/out-add/with-1/diff.patch"
check 'add: git status and the diff leave out the added rule' lacks 'rules/style.md' "$root/out-add/with-1/diff.patch"
check 'add: Claude runs with project settings only' grep -qx '+project,local' "$root/out-add/with-1/diff.patch"
check 'add: the prompt ends with the stop instruction' grep -q 'Make the' "$root/out-add/with-1/prompt.txt"
check 'add: the summary counts the arms' grep -qx 'with: check passed 2/2; instructions loaded 0/2' "$root/output"
check 'add: cost is recorded' [ "$(column "$root/out-add/results.tsv" with 6)" = 0.01 ]
check 'add: the repository is left as it was' [ -z "$(git -C "$repo" status --porcelain)" ]
check 'add: the repository'"'"'s info/exclude is untouched' bash -c "! grep -q style '$repo/.git/info/exclude'"
check 'add: no checkout is left behind' \
  [ -z "$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'try-content.*' -newer "$repo/CLAUDE.md")" ]

mkdir -p "$repo/.claude/rules"
echo 'Use the style.' >"$repo/.claude/rules/style.md"
git -C "$repo" add -A
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q -m 'add the style rule'
spec="$root/remove-spec"
mkdir -p "$spec"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'test -f styled.txt' >"$spec/check.sh"
echo '.claude/rules/style.md' >"$spec/remove.txt"
run -n 1 "$spec" "$root/out-remove"
check 'remove: exits 0' [ "$(cat "$root/status")" = 0 ]
check 'remove: the with-arm keeps the rule' [ "$(column "$root/out-remove/results.tsv" with 3)" = pass ]
check 'remove: the without-arm loses it' [ "$(column "$root/out-remove/results.tsv" without 3)" = fail ]
check 'remove: git status hides the deletion' lacks 'style.md' "$root/out-remove/without-1/diff.patch"

spec="$root/skill-spec"
mkdir -p "$spec"
printf -- '---\nname: hello\ndescription: Says hello.\n---\nSay hi.\n' >"$spec/skill.md"
echo 'skill.md .claude/skills/hello/SKILL.md' >"$spec/add.txt"
echo 'Say hello.' >"$spec/prompt.txt"
echo 'true' >"$spec/check.sh"
run -n 1 "$spec" "$root/out-skill"
check 'skill: the with-arm records one Skill call' [ "$(column "$root/out-skill/results.tsv" with 5)" = 1 ]
check 'skill: the without-arm records none' [ "$(column "$root/out-skill/results.tsv" without 5)" = 0 ]
check 'skill: the summary counts the skill and no instructions' \
  grep -qx 'with: check passed 1/1; skill invoked 1/1' "$root/output"

spec="$root/modify-spec"
mkdir -p "$spec"
printf '# Project\n\nUse the style.\n' >"$spec/CLAUDE.md"
echo 'CLAUDE.md CLAUDE.md' >"$spec/add.txt"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'true' >"$spec/check.sh"
run -n 1 "$spec" "$root/out-modify"
check 'modify: git status hides the changed CLAUDE.md' lacks 'CLAUDE.md' "$root/out-modify/with-1/diff.patch"

(cd "$repo" && "$shell" "$script" --show "$root/out-add") >"$root/show" 2>&1
check 'show: prints the results table' grep -q '^with	1	pass' "$root/show"
(cd "$repo" && "$shell" "$script" --show "$root/out-add" with-1) >"$root/show" 2>&1
check 'show: prints a trial'"'"'s diff' grep -q 'styled.txt' "$root/show"
check 'show: lists what Claude looked at, inside the checkout' grep -qx 'Read src/a.ts' "$root/show"
check 'summary: lists each trial with what it looked at' grep -q '^with-1 pass | .* | looked at: Read src/a.ts$' \
  "$root/output"

run -n 1 --no-hooks "$root/add-spec" "$root/out-nohooks"
check 'no-hooks: a rule without paths loads at launch' [ "$(column "$root/out-nohooks/results.tsv" with 4)" = launch ]
check 'no-hooks: hooks are turned off' grep -q 'disableAllHooks' "$root/out-nohooks/with-1/diff.patch"

spec="$root/scoped-spec"
mkdir -p "$spec"
rule() {
  printf -- '---\npaths:\n  - "%s/**"\n---\n\nEvery function in %s carries the %s annotation.\n' "$1" "$1" "$2"
}
rule src flamingo >"$spec/scoped.md"
rule lib pelican >"$spec/unseen.md"
printf 'scoped.md .claude/rules/scoped.md\nunseen.md .claude/rules/unseen.md\n' >"$spec/add.txt"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'true' >"$spec/check.sh"
run -n 1 --no-hooks "$spec" "$root/out-scoped"
check 'no-hooks: a path rule matching a file Claude read is touched, and one matching none is not' \
  [ "$(column "$root/out-scoped/results.tsv" with 4)" = touched ]

spec="$root/inline-spec"
mkdir -p "$spec"
printf -- '---\npaths: ["**/*.{js,ts}"]\n---\n\nUse the style.\n' >"$spec/inline.md"
echo 'inline.md .claude/rules/inline.md' >"$spec/add.txt"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'true' >"$spec/check.sh"
run -n 1 --no-hooks "$spec" "$root/out-inline"
check 'no-hooks: an inline paths list with braces matches the file Claude read' \
  [ "$(column "$root/out-inline/results.tsv" with 4)" = touched ]

spec="$root/without-spec"
mkdir -p "$spec"
printf '# Trimmed\n' >"$spec/CLAUDE.md"
echo 'CLAUDE.md CLAUDE.md' >"$spec/without.txt"
echo 'Add a file.' >"$spec/prompt.txt"
echo 'grep -q Project CLAUDE.md' >"$spec/check.sh"
run -n 1 "$spec" "$root/out-without"
check 'without: the with-arm keeps the file as it is' [ "$(column "$root/out-without/results.tsv" with 3)" = pass ]
check 'without: the without-arm gets the cut version' [ "$(column "$root/out-without/results.tsv" without 3)" = fail ]
check 'without: git status hides the cut version' lacks 'CLAUDE.md' "$root/out-without/without-1/diff.patch"

spec="$root/bad-spec"
mkdir -p "$spec"
echo 'Add a file.' >"$spec/prompt.txt"
run "$spec" "$root/out-bad"
check 'usage: a spec without check.sh exits 2' [ "$(cat "$root/status")" = 2 ]
echo 'true' >"$spec/check.sh"
run "$spec" "$root/out-bad"
check 'usage: a spec without add.txt, remove.txt or without.txt exits 2' [ "$(cat "$root/status")" = 2 ]
echo 'missing.md .claude/rules/missing.md' >"$spec/add.txt"
run "$spec" "$root/out-bad"
check 'usage: add.txt naming a missing file exits 2' [ "$(cat "$root/status")" = 2 ]
run -n x "$root/add-spec" "$root/out-bad"
check 'usage: a non-numeric run count exits 2' [ "$(cat "$root/status")" = 2 ]

run -h
check 'usage: -h lists the options' grep -q -- '--no-hooks' "$root/output"

printf '%d cases, %d failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
