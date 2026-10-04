#!/usr/bin/env bash
# Checks that a commit message follows Conventional Commits (https://www.conventionalcommits.org/en/v1.0.0/):
#
#   type(scope)!: description
#
# The type is one of `types` below. The scope is optional, in lowercase letters, digits and hyphens. The header is
# at most 72 characters, does not end with a full stop, and is followed by a blank line if a body follows.
# Messages that git writes itself (merges, reverts, fixup!, squash! and amend!) pass unchecked.
#
# Usage: check-commit-msg.sh <message-file>, or - to read the message from standard input.
# Exit status: 0 when the message passes, 1 when it does not, 2 on a usage error.

set -euo pipefail

types='feat|fix|docs|refactor|test|build|ci|chore|revert'
max_header=72

if [ $# -ne 1 ]; then
  echo 'usage: check-commit-msg.sh <message-file | ->' >&2
  exit 2
fi
if [ "$1" = - ]; then
  raw=$(cat)
elif [ -f "$1" ]; then
  raw=$(cat "$1")
else
  echo "check-commit-msg: no such file: $1" >&2
  exit 2
fi

# Drop what git drops when it records the commit: everything below the scissors line that
# `git commit --verbose` adds, comment lines, and blank lines before the first line of text.
message=$(printf '%s\n' "$raw" | sed -e '/^# -* >8 -*$/,$d' -e '/^#/d' | sed -e '/./,$!d')
header=$(printf '%s\n' "$message" | sed -n 1p)
second=$(printf '%s\n' "$message" | sed -n 2p)

fail() {
  printf 'commit-msg: %s\n' "$1" >&2
  printf '  header: %s\n' "$header" >&2
  printf '  expected: type(scope)!: description, where type is one of %s\n' "${types//|/, }" >&2
  printf '  example:  fix(agent-setup): quote the path in the session hook\n' >&2
  exit 1
}

if [ -z "$header" ]; then
  echo 'commit-msg: the message is empty' >&2
  exit 1
fi

case $header in
  'Merge '* | 'Revert "'* | 'fixup! '* | 'squash! '* | 'amend! '*) exit 0 ;;
esac

pattern="^($types)(\([a-z0-9][a-z0-9-]*\))?!?: [^ ]"
if ! [[ $header =~ $pattern ]]; then
  fail 'the header does not follow Conventional Commits'
fi
if [ "${#header}" -gt "$max_header" ]; then
  fail "the header is ${#header} characters, over the limit of $max_header"
fi
case $header in
  *.) fail 'the header ends with a full stop' ;;
esac
if [ -n "$second" ]; then
  fail 'the header must be followed by a blank line before the body'
fi
